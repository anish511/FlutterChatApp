//@dart=2.9
import 'package:chat_app/helper/helperfunctions.dart';
import 'package:chat_app/views/groupChat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../helper/theme.dart';
import '../services/database.dart';
import '../widgets/widget.dart';

class GroupSearchScreen extends StatefulWidget {


  @override
  State<GroupSearchScreen> createState() => _GroupSearchScreenState();
}

class _GroupSearchScreenState extends State<GroupSearchScreen> {

  DatabaseMethods databaseMethods = new DatabaseMethods();
  TextEditingController searchController = new TextEditingController();

  bool isLoading = false;
  QuerySnapshot searchSnapshot;
  bool hasUserSearched = false;
  String userName = "";
  bool isJoined = false;
  User user;

  @override
  void initState() {
    super.initState();
    getCurrentUserIdandName();
  }

  getCurrentUserIdandName() async {
    await HelperFunctions.getUserNameSharedPreference().then((val) {
      setState(() {
        userName = val;
      });
    });
    user = FirebaseAuth.instance.currentUser;
  }

  String getName(String r) {
    return r.substring(r.indexOf("_") + 1);
  }

  String getId(String res) {
    return res.substring(0, res.indexOf("_"));
  }


  // Widget SearchTile({String userName, String userEmail}){
  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: 24,vertical: 16),
  //     child: Row(
  //       children: [
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(userName, style: TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 17
  //             ),),
  //             Text(userEmail, style: TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 17
  //             ),)
  //           ],
  //         ),
  //         Spacer(),
  //         GestureDetector(
  //           onTap: (){
  //              createChatroomAndStartConversation(
  //                  userName: userName
  //              );
  //           },
  //           child: Container(
  //             decoration: BoxDecoration(
  //                 color: Colors.blue,
  //                 borderRadius: BorderRadius.circular(30)
  //             ),
  //             padding: EdgeInsets.symmetric(horizontal: 16,vertical: 16),
  //             child: Text("Message", style: TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 16
  //             ),),
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: appBarMain(context),
      ),
      body: Container(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Color(0x54FFFFFF),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                        controller: searchController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Search username...",
                          hintStyle: TextStyle(
                              color: Colors.white54
                          ),
                          border: InputBorder.none,
                        ),
                      )
                  ),
                  GestureDetector(
                    onTap: (){
                      initiateSearchMethod();
                    },
                    child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                                  const Color(0x36FFFFFF),
                                  const Color(0x0FFFFFFF),
                                ]
                            ),
                            borderRadius: BorderRadius.circular(42)
                        ),
                        padding: EdgeInsets.all(10),
                        child: Image.asset("assets/images/search_white.png")),
                  )
                ],
              ),
            ),
            isLoading
                ? Center(
              child: CircularProgressIndicator(
                  color: CustomTheme.colorAccent),
            )
                : groupList(),
          ],
        ),
      ),
    );
  }

  initiateSearchMethod() async {
    if (searchController.text.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      await databaseMethods
          .searchByGroupName(searchController.text)
          .then((snapshot) {
        setState(() {
          searchSnapshot = snapshot;
          isLoading = false;
          hasUserSearched = true;
        });
      });
    }
  }

  groupList() {
    return hasUserSearched
        ? ListView.builder(
      shrinkWrap: true,
      itemCount: searchSnapshot.docs.length,
      itemBuilder: (context, index) {
        return groupTile(
          userName,
          searchSnapshot.docs[index]['groupId'],
          searchSnapshot.docs[index]['groupName'],
          searchSnapshot.docs[index]['admin'],
        );
      },
    )
        : Container();
  }

  joinedOrNot(
      String userName, String groupId, String groupname, String admin) async {
    await databaseMethods
        .isUserJoined(groupname, groupId, userName,user.uid)
        .then((value) {
      setState(() {
        isJoined = value;
      });
    });
  }

  Widget groupTile(
      String userName, String groupId, String groupName, String admin) {
    // function to check whether user already exists in group
    joinedOrNot(userName, groupId, groupName, admin);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: CustomTheme.colorAccent,
        child: Text(
          groupName.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title:
      Text(groupName, style: const TextStyle(color: Colors.white,fontWeight: FontWeight.w600)),
      subtitle: Text("Admin: ${getName(admin)}", style: TextStyle(color: Colors.white60)),
      trailing: InkWell(
        onTap: () async {
          await databaseMethods
              .toggleGroupJoin(groupId, userName, groupName,user.uid);
          if (isJoined) {
            setState(() {
              isJoined = !isJoined;
            });
            showSnackbar(context, Colors.green, "Successfully joined the group");
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) =>
                  GroupChat(
                      groupId: groupId,
                      groupName: groupName,
                      userName: userName)));
            });
          } else {
            setState(() {
              isJoined = !isJoined;
              showSnackbar(context, Colors.red, "Left the group $groupName");
            });
          }
        },
        child: isJoined
            ? Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.redAccent,
            border: Border.all(color: Colors.white, width: 1),
          ),
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: const Text(
            "Leave",
            style: TextStyle(color: Colors.white),
          ),
        )
            : Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: CustomTheme.colorAccent,
          ),
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: const Text("Join Now",
              style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}


