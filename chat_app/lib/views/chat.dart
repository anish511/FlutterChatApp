//@dart=2.9
import 'dart:io';
import 'package:chat_app/helper/constants.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/widgets/widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/theme.dart';


class Chat extends StatefulWidget {
  final String chatRoomId;
  final String username;

  Chat({this.chatRoomId,this.username});

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat>  {

  Stream chats;
  TextEditingController messageEditingController = new TextEditingController();

  String image = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT2pVWhgXilxQ894sH6mDq-V-oDhoPLEYWUd7m-fh4f0lZIzzGeLaUEObGOsMouGlRA0XM&usqp=CAU';
  String about = "Loading...";

  Future<void> fetchImages() async {

    QuerySnapshot searchSnapshot;
    DatabaseMethods databaseMethods = new DatabaseMethods();
    String imageName;
    databaseMethods.searchByName(widget.username).then((val){
      searchSnapshot = val;
      print("username: " + widget.username);
      imageName = searchSnapshot.docs[0].get('userImageUrl').toString();
      about = searchSnapshot.docs[0].get('intro').toString();
    });

    //String imageName = searchSnapshot.docs[0].get('userImageUrl').toString();
    final ListResult result = await FirebaseStorage.instance
        .ref()
        .child('file')
        .child(imageName)
        .list();
    final List<Reference> allFiles = result.items;
    print(allFiles.length);
    String fileUrl;

    await Future.forEach<Reference>(allFiles, (file) async {
      print(file.fullPath);
      if(file.fullPath.substring(5) == imageName) {
        fileUrl = await file.getDownloadURL();
        print(fileUrl);
      }
    });
    print("last time:" + fileUrl.toString());
    this.image = fileUrl;

    setState(() {});
  }

  getImage() async {
    await fetchImages();
    print("image in get image" + image);
  }


  @override
  void initState() {
    DatabaseMethods().getChats(widget.chatRoomId).then((val) {
      setState(() {
        chats = val;
      });
    });
    super.initState();
   getImage();
  }

  Future<void> _savedChatId(String value) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("inRoomChatId", value);
  }

  Widget chatMessages(){
    return StreamBuilder(
      stream: chats,
      builder: (context, snapshot){
        return snapshot.hasData  ?  ListView.builder(
            itemCount: snapshot.data.docs.length,
            itemBuilder: (context, index){
              return MessageTile(
                messageRef: snapshot.data.docs[index].reference,
                message: snapshot.data.docs[index].get("message"),
                sender: snapshot.data.docs[index].get("sendBy"),
                sendByMe: Constants.myName == snapshot.data.docs[index].get("sendBy"),
              );
            }) : Container();
        //return Container();
      },
    );
  }

  addMessage() async {
    if (messageEditingController.text.isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        "sendBy": Constants.myName,
        "message": messageEditingController.text,
        'time': DateTime
            .now()
            .millisecondsSinceEpoch,
      };

      DatabaseMethods().addMessage(widget.chatRoomId, chatMessageMap);


      setState(() {
        messageEditingController.text = "";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:ListTile(
            leading:Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: CustomTheme.colorAccent,
                  borderRadius: BorderRadius.circular(30),
                ),
                // child: Text( fetchImages().toString().substring(0,1),
                //     textAlign: TextAlign.center
                //     style: TextStyle(
                //         color: Colors.white,
                //         fontSize: 18,
                //         fontFamily: 'OverpassRegular',
                //         fontWeight: FontWeight.w600)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.network(
                    image,
                    width: 50,
                    height: 50,
                    fit: BoxFit.fitHeight,
                  ),
                )
            ),
            title: Text(widget.username,
                textAlign: TextAlign.start,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'OverpassRegular',
                    fontWeight: FontWeight.w800)),

            subtitle: Text(about,
                textAlign: TextAlign.start,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'OverpassRegular',
                    fontWeight: FontWeight.w500))

        ),
      ),
      body: Container(
        child: Stack(
          children: [
            chatMessages(),

            Container(alignment: Alignment.bottomCenter,
              width: MediaQuery
                  .of(context)
                  .size
                  .width,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: Color(0x54FFFFFF),
                child: Row(
                  children: [
                    Expanded(
                        child: TextField(
                          controller: messageEditingController,
                          style: simpleTextStyle(),
                          decoration: InputDecoration(
                              hintText: "Message ...",
                              hintStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              border: InputBorder.none
                          ),
                        )),
                    SizedBox(width: 16,),
                    GestureDetector(
                      onTap: () {
                        addMessage();
                      },
                      child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [
                                    const Color(0x36FFFFFF),
                                    const Color(0x0FFFFFFF)
                                  ],
                                  begin: FractionalOffset.topLeft,
                                  end: FractionalOffset.bottomRight
                              ),
                              borderRadius: BorderRadius.circular(40)
                          ),
                          padding: EdgeInsets.all(12),
                          child: Image.asset("assets/images/send.png",
                            height: 25, width: 25,)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),




      ),
    );
  }


}

class MessageTile extends StatelessWidget {

  final dynamic messageRef;
  final String message;
  final String sender;
  final bool sendByMe;

  MessageTile({this.messageRef,this.message,this.sender ,this.sendByMe});

  deleteThisChat() async {
    await FirebaseFirestore.instance.runTransaction((Transaction myTransaction) async {
      await myTransaction.delete(messageRef);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet<void>(context: context,
            builder: (BuildContext context) {
              return Container(
                  child: new Wrap(
                      children: <Widget>[
                  new ListTile(
                  leading: new Icon(Icons.delete),
                  title: new Text('Delete'),
                  onTap: () {
                    deleteThisChat();
                  }
              )
              ]
              )
              );
            });
      },
      child: Container(

        padding: EdgeInsets.only(
            top: 8,
            bottom: 8,
            left: sendByMe ? 0 : 24,
            right: sendByMe ? 24 : 0),
        alignment: sendByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: sendByMe
              ? EdgeInsets.only(left: 30)
              : EdgeInsets.only(right: 30),
          padding: EdgeInsets.only(
              top: 17, bottom: 17, left: 20, right: 20),
          decoration: BoxDecoration(
              borderRadius: sendByMe ? BorderRadius.only(
                  topLeft: Radius.circular(23),
                  topRight: Radius.circular(23),
                  bottomLeft: Radius.circular(23)
              ) :
              BorderRadius.only(
                  topLeft: Radius.circular(23),
                  topRight: Radius.circular(23),
                  bottomRight: Radius.circular(23)),
              gradient: LinearGradient(
                colors: sendByMe ? [
                  const Color(0xff007EF4),
                  const Color(0xff2A75BC)
                ]
                    : [
                  const Color(0x1AFFFFFF),
                  const Color(0x1AFFFFFF)
                ],
              )
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sender.toUpperCase(),
                textAlign: TextAlign.start,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(message,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'OverpassRegular',
                  ))
            ],
          ),

        ),
      ),
    );
  }
}