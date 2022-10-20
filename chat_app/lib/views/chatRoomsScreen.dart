//@dart=2.9
import 'package:chat_app/helper/authenticate.dart';
import 'package:chat_app/helper/constants.dart';
import 'package:chat_app/helper/helperfunctions.dart';
import 'package:chat_app/helper/theme.dart';
import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/views/chat.dart';
import 'package:chat_app/views/search.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'groupScreen.dart';
import 'my_drawer_header.dart';

class ChatRoom extends StatefulWidget {
  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  Stream chatRooms;

  @override
  void initState() {
    getUserInfogetChats();
    super.initState();
  }

  getUserInfogetChats() async {
    Constants.myName = await HelperFunctions.getUserNameSharedPreference();
    DatabaseMethods().getUserChats(Constants.myName).then((snapshots) {
      setState(() {
        chatRooms = snapshots;
        print(
            "we got the data + ${chatRooms.toString()} this is name  ${Constants.myName}");
      });
    });
  }

  Widget chatRoomsList() {
    return StreamBuilder(
      stream: chatRooms,
      builder: (context, snapshot) {
        return snapshot.hasData ? ListView.builder(
            itemCount: snapshot.data.docs.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return ChatRoomTile(
                userName: snapshot.data.docs[index].get('chatroomid')
                    .toString()
                    .replaceAll("_", "")
                    .replaceAll(Constants.myName, ""),
                chatRoomId: snapshot.data.docs[index].get("chatroomid"),
                roomRef: snapshot.data.docs[index].reference,
              );
            })
            : Container();
        //return Container();
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          "assets/images/logo.png",
          height: 40,
        ),
        elevation: 0.0,
        centerTitle: false,
        actions: [
          // GestureDetector(
          //   onTap: () {
          //     AuthService().signOut();
          //     Navigator.pushReplacement(context,
          //         MaterialPageRoute(builder: (context) => Authenticate()));
          //   },
          //   child: Container(
          //       padding: EdgeInsets.symmetric(horizontal: 16),
          //       child: Icon(Icons.exit_to_app)),
          // )
        ],
      ),
      drawer: Drawer(
        child: SingleChildScrollView(
          child: Container(
            child: Column(
              children: [
                MyHeaderDrawer(),
                MyDrawerList(),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        child: chatRoomsList(),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.search),
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => SearchScreen()));
        },
      ),
    );
  }

  Widget MyDrawerList() {
    return Container(
      padding: EdgeInsets.only(
        top: 15,
      ),
      child: Column(
        // shows the list of menu drawer
        children: [
          menuItem(6, "Single Chat", Icons.man, true),
          Divider(),
          menuItem(7, "Group Chat", Icons.group_add, false),
          Divider(),
          menuItem(8, "Logout", Icons.logout, false),
        ],
      ),
    );
  }

  Widget menuItem(int id, String title, IconData icon, bool selected) {
    return Material(
      color: selected ? Colors.grey[300] : Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          setState(() {

            if (id == 7) {
              //currentPage = DrawerSections.send_feedback;
              Navigator.push(context,  MaterialPageRoute(builder: (context) => GroupScreen()));
            } else if (id == 8) {
             // currentPage = DrawerSections.logout;


                showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Logout"),
                        content: const Text("Are you sure you want to logout?"),
                        actions: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              AuthService().signOut();
                              Navigator.pushReplacement(context,
                                  MaterialPageRoute(builder: (context) => Authenticate()));
                            },
                            icon: const Icon(
                              Icons.done,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      );
                    });




            }
          });
        },
        child: Padding(
          padding: EdgeInsets.all(15.0),
          child: Row(
            children: [
              Expanded(
                child: Icon(
                  icon,
                  size: 20,
                  color: Colors.blue,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


enum DrawerSections {
  Home,
  Favourites,
  MyWallpapers,
  Contacts,
  aboutUs,
  privacy_policy,
  send_feedback,
  logout
}

class ChatRoomTile extends StatefulWidget {

  final String userName;
  final String chatRoomId;
  final dynamic roomRef;

  ChatRoomTile({this.userName,this.chatRoomId,this.roomRef});
  @override
  _ChatRoomTileState createState() => _ChatRoomTileState();
}

class _ChatRoomTileState extends State<ChatRoomTile> {

  String image = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT2pVWhgXilxQ894sH6mDq-V-oDhoPLEYWUd7m-fh4f0lZIzzGeLaUEObGOsMouGlRA0XM&usqp=CAU';
  String about = "Loading...";
  
  Future<void> fetchImages() async {

    QuerySnapshot searchSnapshot;
    DatabaseMethods databaseMethods = new DatabaseMethods();
    String imageName;
    databaseMethods.searchByName(widget.userName).then((val){
      searchSnapshot = val;
      print("username: " + widget.userName);
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
  void initState()  {
    // TODO: implement initState
    super.initState();
    getImage();

  }

  deleteThisChat() async {
    DatabaseMethods().deleteChatRoom(widget.chatRoomId);
    await FirebaseFirestore.instance.runTransaction((Transaction myTransaction) async {
      await myTransaction.delete(widget.roomRef);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => Chat(
              chatRoomId: widget.chatRoomId,
              username: widget.userName,

            )
        ));
      },
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
        color: Colors.black26,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: ListTile(
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
           title: Text(widget.userName,
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
    );
  }
}