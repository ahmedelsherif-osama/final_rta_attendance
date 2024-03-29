import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_rta_attendance/cubit/app_cubit.dart';
import 'package:final_rta_attendance/models/1_school_model.dart';
import 'package:final_rta_attendance/models/3_student_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChangeDetailsPopup extends StatefulWidget {
  const ChangeDetailsPopup({super.key});
  @override
  State<ChangeDetailsPopup> createState() => _ChangeDetailsPopupState();
}

class _ChangeDetailsPopupState extends State<ChangeDetailsPopup> {
  var schoolModels;
  var _students;
  var _studentDocIds;
  var schoolRoutesNames;
  var _changeSchoolOrBus;
  bool _addingNewSchool = false;
  var newSchoolFirebaseDocId;
  List<DropdownMenuEntry<dynamic>> schoolsDropDownEntries = [];
  List<String>? schoolNames;

  Future<String> fetchSchoolFirebaseIdByName(schoolName) async {
    String docID = "";
    await FirebaseFirestore.instance
        .collection("schools")
        .where("name", isEqualTo: schoolName)
        .get()
        .then((value) => docID = value.docs.first.id);

    BlocProvider.of<AppCubit>(context).updateState(
        BlocProvider.of<AppCubit>(context)
            .state
            .copyWith(currentSchoolFirebaseDocId: docID));
    return docID;
  }

  Future<SchoolModel> fetchSchoolFromFirebaseByName(schoolName) async {
    SchoolModel school = SchoolModel.empty();
    await FirebaseFirestore.instance
        .collection("schools")
        .where("name", isEqualTo: schoolName)
        .get()
        .then(
            (value) => school = SchoolModel.fromJson(value.docs.first.data()));

    return school;
  }

  Future<void> createNewFirebaseDoc(collectionPath, jsonDoc) async {
    try {
      await FirebaseFirestore.instance.collection(collectionPath).add(jsonDoc);
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> updateBusRouteNumberOnStudentsOnFirebase(
      newCurrentBusRouteFromState, oldCurrentBusRoute) async {
    var studentsOfBusRouteDocIds = [];
    await FirebaseFirestore.instance
        .collection("students")
        .where("schoolName", isEqualTo: oldCurrentBusRoute.schoolName)
        .where("busRouteNumber",
            isEqualTo: oldCurrentBusRoute.busRouteNumber.toString())
        .get()
        .then((value) => value.docs.forEach((element) {
              studentsOfBusRouteDocIds.add(element.id);
            }));
    for (int index = 0; index < studentsOfBusRouteDocIds.length; index++) {
      await FirebaseFirestore.instance
          .collection("students")
          .doc(studentsOfBusRouteDocIds[index])
          .update(
              {"busRouteNumber": newCurrentBusRouteFromState.busRouteNumber});
    }
  }

  Future<void> updateSchoolNameOnStudentsOnFirebase(
      newCurrentBusRouteFromState, oldCurrentBusRoute) async {
    var studentsOfBusRouteDocIds = [];
    await FirebaseFirestore.instance
        .collection("students")
        .where("schoolName", isEqualTo: oldCurrentBusRoute.schoolName)
        .where("busRouteNumber", isEqualTo: oldCurrentBusRoute.busRouteNumber)
        .get()
        .then((value) => value.docs.forEach((element) {
              studentsOfBusRouteDocIds.add(element.id);
            }));
    for (int index = 0; index < studentsOfBusRouteDocIds.length; index++) {
      await FirebaseFirestore.instance
          .collection("students")
          .doc(studentsOfBusRouteDocIds[index])
          .update({"schoolName": newCurrentBusRouteFromState.schoolName});
    }
  }

  Future<void> updateFirebaseDoc(
      collectionPath, firebaseDocId, fieldName, value) async {
    await FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(firebaseDocId)
        .update({
      fieldName: value,
    });
  }

  void initState() {
    super.initState();
    _fetchSchools().then((schools) {
      setState(() {
        print(schools.isEmpty);
        print(schools[0].name);
        // Update schoolModels instead of schoolNames
        schoolModels = schools;
        print(schoolModels.isEmpty);
        print(schoolModels[0].name);
        // Initialize and clear the dropdown items list
        schoolsDropDownEntries = [];

        // Populate dropdown items here
        schoolModels.forEach(
            (schoolModel) => schoolsDropDownEntries.add(DropdownMenuEntry(
                  value: schoolModel.name,
                  label: schoolModel.name,
                )));
      });
    });
  }

  Future<List> _fetchSchools() async {
    try {
      var schoolsSnapshot =
          await FirebaseFirestore.instance.collection('schools').get();

      // Convert QuerySnapshot to List<SchoolModel>
      List<SchoolModel> schools = schoolsSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return SchoolModel.fromJson(data);
      }).toList();
      print(schools.isEmpty);
      print(schools[0].name);
      return schools;
    } catch (e) {
      // Handle any errors that occurred during the fetch
      print('Error fetching schools: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final busRouteNumberController = TextEditingController();
    busRouteNumberController.text = BlocProvider.of<AppCubit>(context)
        .state
        .currentBusRoute
        .busRouteNumber
        .toString();
    final schoolNameController = TextEditingController();

    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var busRoute = context.read<AppCubit>().state.currentBusRoute;

            var school = context.read<AppCubit>().state.currentSchool;
            var studentCount = snapshot.data!.docs
                .where((element) =>
                    element['busRouteNumber'].toString() ==
                        busRoute.busRouteNumber.toString() &&
                    element['schoolName'].toString() == school.name.toString())
                .length;
            var studentList = snapshot.data!.docs
                .where((element) =>
                    element['busRouteNumber'].toString() ==
                        busRoute.busRouteNumber.toString() &&
                    element['schoolName'].toString() == school.name.toString())
                .toList();

            var docIds = [];
            snapshot.data!.docs.forEach(
              (element) {
                docIds.add(element.id);
              },
            );

            return Dialog(
              child: Container(
                height: height / 2,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Radio(
                            value: _changeSchoolOrBus,
                            groupValue: "Change Bus Route Number",
                            onChanged: (value) {
                              setState(() {
                                _changeSchoolOrBus = "Change Bus Route Number";
                              });
                            }),
                        Text("Change Bus Route Number"),
                      ],
                    ),
                    Row(
                      children: [
                        Radio(
                            value: _changeSchoolOrBus,
                            groupValue: "Change School",
                            onChanged: (value) {
                              setState(() {
                                _changeSchoolOrBus = "Change School";
                              });
                            }),
                        Text("Change School"),
                      ],
                    ),
                    if (_changeSchoolOrBus == "Change Bus Route Number")
                      TextFormField(
                        controller: busRouteNumberController,
                      ),
                    if (_changeSchoolOrBus == "Change School")
                      Column(
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _addingNewSchool,
                                onChanged: (value) {
                                  setState(() {
                                    _addingNewSchool = value!;
                                  });
                                },
                              ),
                              Text("Adding New School"),
                            ],
                          ),
                          if (_addingNewSchool == true)
                            TextFormField(
                              controller: schoolNameController,
                              decoration:
                                  InputDecoration(labelText: 'New School Name'),
                            ),
                          if (_addingNewSchool == false)
                            DropdownMenu(
                              dropdownMenuEntries: schoolsDropDownEntries,
                              onSelected: (value) {
                                schoolNameController.text = value;
                              },
                            )
                        ],
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                            onPressed: () async {
                              if (_changeSchoolOrBus ==
                                  "Change Bus Route Number") {
                                // 1. update busroutenumber on currentbusroute on state
                                final oldCurrentBusRoute = context
                                    .read<AppCubit>()
                                    .state
                                    .currentBusRoute;
                                final updatedBusRouteNumber =
                                    int.tryParse(busRouteNumberController.text);

                                if (updatedBusRouteNumber != null) {
                                  final updatedCurrentBusRoute =
                                      oldCurrentBusRoute.copyWith(
                                          busRouteNumber:
                                              updatedBusRouteNumber);
                                  // rest of your code

                                  final currentState =
                                      context.read<AppCubit>().state;
                                  final newState = currentState.copyWith(
                                      currentBusRoute: updatedCurrentBusRoute);
                                  context
                                      .read<AppCubit>()
                                      .updateState(newState);

                                  // 2. update busroutenumber on currentbusroute on firebase
                                  final currentBusRouteDocId = context
                                      .read<AppCubit>()
                                      .state
                                      .currentBusRouteFirebaseDocId;
                                  final newCurrentBusRouteFromState = context
                                      .read<AppCubit>()
                                      .state
                                      .currentBusRoute;
                                  updateFirebaseDoc(
                                      "busRoutes",
                                      currentBusRouteDocId,
                                      "busRouteNumber",
                                      newCurrentBusRouteFromState
                                          .busRouteNumber);

                                  // 3. update busroutesnumber on students on firebase
                                  updateBusRouteNumberOnStudentsOnFirebase(
                                      newCurrentBusRouteFromState,
                                      oldCurrentBusRoute);

                                  // 4. update busroutenumber on currentschool on state
                                  final oldCurrentSchool = context
                                      .read<AppCubit>()
                                      .state
                                      .currentSchool;
                                  final oldCurrentSchoolRoutesNames =
                                      oldCurrentSchool.routesNames;
                                  List<String> newCurrentSchoolRoutesNames = [];
                                  oldCurrentSchoolRoutesNames
                                      .forEach((element) {
                                    if (element !=
                                        oldCurrentBusRoute.busRouteNumber
                                            .toString()) {
                                      newCurrentSchoolRoutesNames.add(element);
                                    }
                                  });
                                  newCurrentSchoolRoutesNames.add(
                                      newCurrentBusRouteFromState.busRouteNumber
                                          .toString());
                                  final newCurrentSchool =
                                      oldCurrentSchool.copyWith(
                                          routesNames:
                                              newCurrentSchoolRoutesNames);
                                  final oldState =
                                      context.read<AppCubit>().state;
                                  final newState2 = oldState.copyWith(
                                      currentSchool: newCurrentSchool);
                                  context
                                      .read<AppCubit>()
                                      .updateState(newState2);

                                  // 5. update busroutenumber on currentschool on firebase
                                  final currentSchoolDocId = context
                                      .read<AppCubit>()
                                      .state
                                      .currentSchoolFirebaseDocId;
                                  updateFirebaseDoc(
                                      "schools",
                                      currentSchoolDocId,
                                      "routesNames",
                                      newCurrentSchoolRoutesNames);
                                } else {
                                  // Handle the case where the text is not a valid integer
                                  print("Invalid integer entered");
                                }
                              } else {
                                if (_addingNewSchool) {
                                  // 0. check if a school with same name already exists
                                  if (schoolNames!
                                      .contains(schoolNameController.text)) {
                                    print("error, school already exists");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.red,
                                        content: Text(
                                            'A school with this name already exists'),
                                        behavior: SnackBarBehavior.floating,
                                        margin: EdgeInsets.only(bottom: 300),
                                      ),
                                    );
                                    Future.delayed(Duration(seconds: 5));
                                    Navigator.of(context).pop();
                                    return;
                                  }
                                  // 1. update schoolname on busroute on state
                                  final oldCurrentBusRoute = context
                                      .read<AppCubit>()
                                      .state
                                      .currentBusRoute;
                                  final newCurrentBusRoute =
                                      oldCurrentBusRoute.copyWith(
                                    schoolName: schoolNameController.text,
                                  );
                                  final oldState =
                                      context.read<AppCubit>().state;
                                  final newState = oldState.copyWith(
                                      currentBusRoute: newCurrentBusRoute);
                                  context
                                      .read<AppCubit>()
                                      .updateState(newState);

                                  // 2. update schoolname on busroute on firebase
                                  final currentBusRouteDocID = context
                                      .read<AppCubit>()
                                      .state
                                      .currentBusRouteFirebaseDocId;
                                  final currentBusRouteSchoolNameFromState =
                                      context
                                          .read<AppCubit>()
                                          .state
                                          .currentBusRoute
                                          .schoolName;
                                  updateFirebaseDoc(
                                      "busRoutes",
                                      currentBusRouteDocID,
                                      "schoolName",
                                      currentBusRouteSchoolNameFromState);

                                  // 3. update schoolname on students on firebase
                                  final newCurrentBusRouteFromState = context
                                      .read<AppCubit>()
                                      .state
                                      .currentBusRoute;
                                  updateSchoolNameOnStudentsOnFirebase(
                                      newCurrentBusRouteFromState,
                                      oldCurrentBusRoute);

                                  // 3.51 update routesnames on current school on state
                                  final oldCurrentSchool = context
                                      .read<AppCubit>()
                                      .state
                                      .currentSchool;
                                  final List<String>
                                      NewCurrentSchoolRoutesNames = [];
                                  oldCurrentSchool.routesNames
                                      .forEach((element) {
                                    if (element !=
                                        oldCurrentBusRoute.busRouteNumber
                                            .toString()) {
                                      NewCurrentSchoolRoutesNames.add(element);
                                    }
                                  });
                                  print(NewCurrentSchoolRoutesNames);
                                  final newCurrentSchool =
                                      oldCurrentSchool.copyWith(
                                          routesNames:
                                              NewCurrentSchoolRoutesNames);
                                  final oldState4 =
                                      context.read<AppCubit>().state;
                                  final newState4 = oldState4.copyWith(
                                      currentSchool: newCurrentSchool);
                                  context
                                      .read<AppCubit>()
                                      .updateState(newState4);
                                  print(
                                      "updated school routesnames on state ${context.read<AppCubit>().state.currentSchool.routesNames}");

                                  // 3.52 update routesnames on current school on firebase
                                  final currentSchoolFirebaseDocId = context
                                      .read<AppCubit>()
                                      .state
                                      .currentSchoolFirebaseDocId;
                                  final newRoutesNamesFromState = context
                                      .read<AppCubit>()
                                      .state
                                      .currentSchool
                                      .routesNames;
                                  updateFirebaseDoc(
                                      "schools",
                                      currentSchoolFirebaseDocId,
                                      "routesNames",
                                      newRoutesNamesFromState);

                                  // 4. update schoolname/new school on currentschool on state
                                  final currentBusRouteNumber = context
                                      .read<AppCubit>()
                                      .state
                                      .currentBusRoute
                                      .busRouteNumber;
                                  final newSchool = SchoolModel(
                                      name: schoolNameController.text,
                                      routesNames: [
                                        currentBusRouteNumber.toString()
                                      ]);
                                  final oldState2 =
                                      context.read<AppCubit>().state;
                                  final newState2 = oldState2.copyWith(
                                      currentSchool: newSchool);
                                  context
                                      .read<AppCubit>()
                                      .updateState(newState2);

                                  // 5. update schoolname/new school on firebase
                                  final newSchoolFromState = context
                                      .read<AppCubit>()
                                      .state
                                      .currentSchool;
                                  final newSchoolFromStateJson =
                                      newSchoolFromState.toJson();
                                  createNewFirebaseDoc(
                                      "schools", newSchoolFromStateJson);

                                  // 6. clear school firebase doc id on state, for now, when we go back to the school screen, or school list screen
                                  final oldState5 =
                                      context.read<AppCubit>().state;
                                  final newState5 = oldState5.copyWith(
                                      currentSchoolFirebaseDocId: "");
                                  context
                                      .read<AppCubit>()
                                      .updateState(newState5);
                                }
                                if (!_addingNewSchool) {
                                  print("if is working");
                                  // 2. if not, then check if in the new school a route with same number exists, er if tr
                                  final currentBusRoute = context
                                      .read<AppCubit>()
                                      .state
                                      .currentBusRoute;
                                  schoolModels
                                      .forEach((model) => print(model.name));
                                  print(schoolNameController.text);
                                  final newSchool = schoolModels.firstWhere(
                                      (element) =>
                                          element.name ==
                                          schoolNameController.text);

                                  final newSchoolContainsSameBusRouteNumberAlready =
                                      newSchool.routesNames.contains(
                                          currentBusRoute.busRouteNumber
                                              .toString());
                                  print(
                                      " new school contains same busroute number ${newSchoolContainsSameBusRouteNumberAlready}");
                                  if (newSchoolContainsSameBusRouteNumberAlready) {
                                    print(
                                        "error busroutenumber already exists within new school");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.only(bottom: 300),
                                          backgroundColor: Colors.red,
                                          content: Text(
                                              "A bus route number with same number already exists under the chosen school")),
                                    );
                                    Navigator.of(context).pop();
                                  }
                                  // // 3. if not, then update school name on cstudents from both schoolnbus on firebase
                                  if (studentList.isNotEmpty &&
                                      studentList != null) {
                                    print(studentList[0]['name']);
                                    print(docIds[0]);
                                    docIds.forEach((element) {
                                      updateFirebaseDoc(
                                          "students",
                                          element,
                                          "schoolName",
                                          schoolNameController.text);
                                    });
                                  }
                                  // 4. remove busroute number from current school on state
                                  var oldCurrentSchool = context
                                      .read<AppCubit>()
                                      .state
                                      .currentSchool;
                                  var oldRoutesNames =
                                      oldCurrentSchool.routesNames;
                                  var newRoutesNames = <String>[];
                                  print("here");
                                  oldRoutesNames.forEach((element) {
                                    if (element.toString() !=
                                        busRouteNumberController.text
                                            .toString()) {
                                      newRoutesNames.add(element);
                                    }
                                  });
                                  var newCurrentSchool = oldCurrentSchool
                                      .copyWith(routesNames: newRoutesNames);
                                  var oldState = context.read<AppCubit>().state;
                                  var newState = oldState.copyWith(
                                      currentSchool: newCurrentSchool);
                                  context
                                      .read<AppCubit>()
                                      .updateState(newState);
                                  print(context
                                      .read<AppCubit>()
                                      .state
                                      .currentSchool
                                      .routesNames);
                                  print(context
                                      .read<AppCubit>()
                                      .state
                                      .currentSchool
                                      .name);

                                  // 5. remove busroute number from current school on firebase
                                  final currentSchool = context
                                      .read<AppCubit>()
                                      .state
                                      .currentSchool;
                                  final newRoutesNames2 =
                                      currentSchool.routesNames;
                                  final currentSchoolDocId = context
                                      .read<AppCubit>()
                                      .state
                                      .currentSchoolFirebaseDocId;
                                  updateFirebaseDoc(
                                      "schools",
                                      currentSchoolDocId,
                                      "routesNames",
                                      newRoutesNames2);

                                  try {
                                    // 6. update current school on state to be the one with the right name, fetch from db
                                    var newSchoolName =
                                        schoolNameController.text;
                                    var newSchool2 =
                                        await fetchSchoolFromFirebaseByName(
                                            newSchoolName);

                                    var oldState2 =
                                        context.read<AppCubit>().state;
                                    var newState2 = oldState2.copyWith(
                                        currentSchool: newSchool2);
                                    context
                                        .read<AppCubit>()
                                        .updateState(newState2);

                                    //testing
                                    var testSchool2Name = context
                                        .read<AppCubit>()
                                        .state
                                        .currentSchool
                                        .name;
                                    print(
                                        "usecase 6: testing $testSchool2Name");

                                    // 7. update current school on state to have the new bus route number added to it
                                    var currentBusRouteNumber = context
                                        .read<AppCubit>()
                                        .state
                                        .currentBusRoute
                                        .busRouteNumber;
                                    var currentSchool2 = context
                                        .read<AppCubit>()
                                        .state
                                        .currentSchool;

                                    var newCurrentSchool2RoutesNames =
                                        List<String>.from(
                                            currentSchool2.routesNames);
                                    newCurrentSchool2RoutesNames
                                        .add(currentBusRouteNumber.toString());

                                    var newCurrentSchool2 =
                                        currentSchool2.copyWith(
                                            routesNames:
                                                newCurrentSchool2RoutesNames);
                                    var oldState3 =
                                        context.read<AppCubit>().state;
                                    var newState3 = oldState3.copyWith(
                                        currentSchool: newCurrentSchool2);
                                    context
                                        .read<AppCubit>()
                                        .updateState(newState3);

                                    //testing
                                    var testSchool3 = context
                                        .read<AppCubit>()
                                        .state
                                        .currentSchool;
                                    print(
                                        "usecase 7: testing ${testSchool3.name} ${testSchool3.routesNames}");

                                    // 8. update current docid (on state) to be for this new school
                                    var oldCurrentSchoolDocId = context
                                        .read<AppCubit>()
                                        .state
                                        .currentSchoolFirebaseDocId;
                                    var currentSchoolName = context
                                        .read<AppCubit>()
                                        .state
                                        .currentSchool
                                        .name;
                                    var newCurrentSchoolDocId;
                                    fetchSchoolFirebaseIdByName(
                                            currentSchoolName)
                                        .then((value) {
                                      newCurrentSchoolDocId = value;

                                      var oldState4 =
                                          context.read<AppCubit>().state;
                                      var newState4 = oldState4.copyWith(
                                          currentSchoolFirebaseDocId:
                                              newCurrentSchoolDocId);
                                      context
                                          .read<AppCubit>()
                                          .updateState(newState4);

                                      //testing
                                      var testDocID1 = oldCurrentSchoolDocId;
                                      var testDocId2 = context
                                          .read<AppCubit>()
                                          .state
                                          .currentSchoolFirebaseDocId;
                                      print(
                                          "usecase 8  testing $testDocID1  $testDocId2");
                                      var newCurrentSchoolRoutesNames = context
                                          .read<AppCubit>()
                                          .state
                                          .currentSchool
                                          .routesNames;

                                      updateFirebaseDoc(
                                          "schools",
                                          newCurrentSchoolDocId,
                                          "routesNames",
                                          newCurrentSchoolRoutesNames);

                                      var currentBusDocId = context
                                          .read<AppCubit>()
                                          .state
                                          .currentBusRouteFirebaseDocId;
                                      updateFirebaseDoc(
                                          "busRoutes",
                                          currentBusDocId,
                                          "schoolName",
                                          currentSchoolName);
                                    });

                                    // 9. update this new school on Firebase

                                    var newCurrentSchoolRoutesNames = context
                                        .read<AppCubit>()
                                        .state
                                        .currentSchool
                                        .routesNames;

                                    await updateFirebaseDoc(
                                        "schools",
                                        newCurrentSchoolDocId,
                                        "routesNames",
                                        newCurrentSchoolRoutesNames);

                                    Navigator.of(context).pop();
                                  } catch (error) {
                                    print("Error: $error");
                                    // Handle errors as needed
                                  }
                                }
                              }
                              Navigator.of(context).pop();
                            },
                            child: Text("Save")),
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text("Cancel")),
                      ],
                    ),
                  ],
                ),
              ),
            );
          } else {
            return CircularProgressIndicator();
          }
        });
  }
}
