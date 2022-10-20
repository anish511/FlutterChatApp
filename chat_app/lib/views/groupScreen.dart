
import 'package:chat_app/helper/helperfunctions.dart';
import 'package:chat_app/helper/theme.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/views/searchGroup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../helper/authenticate.dart';
import '../services/auth.dart';
import '../widgets/group_tile.dart';
import '../widgets/widget.dart';
import 'chatRoomsScreen.dart';
import 'my_drawer_header.dart';

class GroupScreen extends StatefulWidget {

  final DatabaseMethods databaseMethods = new DatabaseMethods();
  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  String userName = "";
  String email = "";
  AuthService authService = AuthService();
  Stream? groups;
  bool _isLoading = false;
  String groupName = "";

  @override
  void initState() {
    super.initState();
    gettingUserData();
  }

  // string manipulation
  String getId(String res) {
    return res.substring(0, res.indexOf("_"));
  }

  String getName(String res) {
    return res.substring(res.indexOf("_") + 1);
  }

  gettingUserData() async {
    await HelperFunctions.getUserEmailSharedPreference().then((val){
      setState((){
        email = val;
      });
    });
    await HelperFunctions.getUserNameSharedPreference().then((val) {
      setState(() {
        userName = val;
      });
    });

    // getting the list of snapshots in our stream
    await widget.databaseMethods
        .getUserGroups(FirebaseAuth.instance.currentUser!.uid)
        .then((snapshot) {
      setState(() {
        groups = snapshot;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   actions: [
      //     IconButton(
      //         onPressed: () {
      //           nextScreen(context, const SearchPage());
      //         },
      //         icon: const Icon(
      //           Icons.search,
      //         ))
      //   ],
      //   elevation: 0,
      //   centerTitle: true,
      //   backgroundColor: Theme.of(context).primaryColor,
      //   title: const Text(
      //     "Groups",
      //     style: TextStyle(
      //         color: Colors.white, fontWeight: FontWeight.bold, fontSize: 27),
      //   ),
      // ),
      // drawer: Drawer(
      //     child: ListView(
      //       padding: const EdgeInsets.symmetric(vertical: 50),
      //       children: <Widget>[
      //         Icon(
      //           Icons.account_circle,
      //           size: 150,
      //           color: Colors.grey[700],
      //         ),
      //         const SizedBox(
      //           height: 15,
      //         ),
      //         Text(
      //           userName,
      //           textAlign: TextAlign.center,
      //           style: const TextStyle(fontWeight: FontWeight.bold),
      //         ),
      //         const SizedBox(
      //           height: 30,
      //         ),
      //         const Divider(
      //           height: 2,
      //         ),
      //         ListTile(
      //           onTap: () {},
      //           selectedColor: Theme.of(context).primaryColor,
      //           selected: true,
      //           contentPadding:
      //           const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      //           leading: const Icon(Icons.group),
      //           title: const Text(
      //             "Groups",
      //             style: TextStyle(color: Colors.black),
      //           ),
      //         ),
      //         ListTile(
      //           onTap: () {
      //             nextScreenReplace(
      //                 context,
      //                 ProfilePage(
      //                   userName: userName,
      //                   email: email,
      //                 ));
      //           },
      //           contentPadding:
      //           const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      //           leading: const Icon(Icons.group),
      //           title: const Text(
      //             "Profile",
      //             style: TextStyle(color: Colors.black),
      //           ),
      //         ),
      //         ListTile(
      //           onTap: () async {
      //             showDialog(
      //                 barrierDismissible: false,
      //                 context: context,
      //                 builder: (context) {
      //                   return AlertDialog(
      //                     title: const Text("Logout"),
      //                     content: const Text("Are you sure you want to logout?"),
      //                     actions: [
      //                       IconButton(
      //                         onPressed: () {
      //                           Navigator.pop(context);
      //                         },
      //                         icon: const Icon(
      //                           Icons.cancel,
      //                           color: Colors.red,
      //                         ),
      //                       ),
      //                       IconButton(
      //                         onPressed: () async {
      //                           await authService.signOut();
      //                           Navigator.of(context).pushAndRemoveUntil(
      //                               MaterialPageRoute(
      //                                   builder: (context) => const LoginPage()),
      //                                   (route) => false);
      //                         },
      //                         icon: const Icon(
      //                           Icons.done,
      //                           color: Colors.green,
      //                         ),
      //                       ),
      //                     ],
      //                   );
      //                 });
      //           },
      //           contentPadding:
      //           const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      //           leading: const Icon(Icons.exit_to_app),
      //           title: const Text(
      //             "Logout",
      //             style: TextStyle(color: Colors.black),
      //           ),
      //         )
      //       ],
      //     )),
      appBar: AppBar(
        title: Image.asset(
          "assets/images/logo.png",
          height: 40,
        ),
        elevation: 0.0,
        centerTitle: false,
        actions: [
          GestureDetector(
          onTap: () {
             popUpDialog(context);
          },
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.add_box)),
          )
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
         child: groupList(),
       ),
       floatingActionButton: FloatingActionButton(
         child: Icon(Icons.search),
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => GroupSearchScreen()));
        },
        ),
      // body: groupList(),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     popUpDialog(context);
      //   },
      //   elevation: 0,
      //   backgroundColor: Theme.of(context).primaryColor,
      //   child: const Icon(
      //     Icons.add,
      //     color: Colors.white,
      //     size: 30,
      //   ),
      // ),
    );
  }

  popUpDialog(BuildContext context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: ((context, setState) {
            return AlertDialog(
              title: const Text(
                "Create a group",
                textAlign: TextAlign.left,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isLoading == true
                      ? Center(
                    child: CircularProgressIndicator(
                        color: CustomTheme.textColor),
                  )
                      : TextField(
                    onChanged: (val) {
                      setState(() {
                        groupName = val;
                      });
                    },
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: CustomTheme.colorAccent),
                            borderRadius: BorderRadius.circular(20)),
                        errorBorder: OutlineInputBorder(
                            borderSide:
                            const BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(20)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: CustomTheme.colorAccent),
                            borderRadius: BorderRadius.circular(20))),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                      primary: CustomTheme.colorAccent),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (groupName != "") {
                      setState(() {
                        _isLoading = true;
                      });
                      widget.databaseMethods
                          .createGroup(userName,
                          FirebaseAuth.instance.currentUser!.uid, groupName,FirebaseAuth.instance.currentUser!.uid)
                          .whenComplete(() {
                        _isLoading = false;
                      });
                      Navigator.of(context).pop();
                      showSnackbar(
                          context, Colors.green, "Group created successfully.");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      primary: Theme.of(context).primaryColor),
                  child: const Text("CREATE"),
                )
              ],
            );
          }));
        });
  }

  groupList() {
    return StreamBuilder(
      stream: groups,
      builder: (context, AsyncSnapshot snapshot) {
        // make some checks
        if (snapshot.hasData) {
          if (snapshot.data['groups'] != null) {
            if (snapshot.data['groups'].length != 0) {
              return ListView.builder(
                itemCount: snapshot.data['groups'].length,
                itemBuilder: (context, index) {
                  int reverseIndex = snapshot.data['groups'].length - index - 1;
                  return GroupTile(
                      groupId: getId(snapshot.data['groups'][reverseIndex]),
                      groupName: getName(snapshot.data['groups'][reverseIndex]),
                      userName: snapshot.data['name']);
                },
              );
            } else {
              return noGroupWidget();
            }
          } else {
            return noGroupWidget();
          }
        } else {
          return Center(
            child: CircularProgressIndicator(
                color: CustomTheme.colorAccent),
          );
        }
      },
    );
  }



  noGroupWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              popUpDialog(context);
            },
            child: Icon(
              Icons.add_circle,
              color: Colors.blueGrey,
              size: 75,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          const Text(
            "You've not joined any groups, tap on the add icon to create a group or also search from  search button.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          )
        ],
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
          menuItem(6, "Single Chat", Icons.man, false),
          Divider(),
          menuItem(7, "Group Chat", Icons.group_add, true),
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

            if (id == 6) {
              Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (context) => ChatRoom()
              ));
              //currentPage = DrawerSections.send_feedback;
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
