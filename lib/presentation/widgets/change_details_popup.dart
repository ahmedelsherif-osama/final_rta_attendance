import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_rta_attendance/cubit/app_cubit.dart';
import 'package:final_rta_attendance/models/1_school_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChangeDetailsPopup extends StatefulWidget {
  const ChangeDetailsPopup({super.key});
  @override
  State<ChangeDetailsPopup> createState() => _ChangeDetailsPopupState();
}

class _ChangeDetailsPopupState extends State<ChangeDetailsPopup> {
  var _schools;
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
        _schools = schools;
        schoolNames = schools.map((doc) => doc['name'] as String).toList();

        // Initialize and clear the dropdown items list
        schoolsDropDownEntries = [];

        // Populate dropdown items here
        schoolsDropDownEntries = schoolNames!
            .map((name) => DropdownMenuEntry(
                  value: name,
                  label: name,
                ))
            .toList();
      });
    });
  }

  Future<List> _fetchSchools() async {
    try {
      var schools =
          await FirebaseFirestore.instance.collection('schools').get();
      return schools.docs;
      //.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      // Handle any errors that occurred during the fetch
      print('Error fetching schools: $e');
      return [];
    }
  }

  Future<List<SchoolModel>> fetchSchools() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection("schools").get();
    List<SchoolModel>? schools = [];
    querySnapshot.docs
        .map(
            (e) => schools.add(SchoolModel.fromJson(e as Map<String, dynamic>)))
        .toList();
    schools.forEach((element) {
      print("tes ${element.name}");
    });
    return schools;
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
                      decoration: InputDecoration(labelText: 'New School Name'),
                    ),
                  if (_addingNewSchool == false)
                    DropdownMenu(dropdownMenuEntries: schoolsDropDownEntries)
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                    onPressed: () {
                      if (_changeSchoolOrBus == "Change Bus Route Number") {
                        // 1. update busroutenumber on currentbusroute on state
                        final oldCurrentBusRoute =
                            context.read<AppCubit>().state.currentBusRoute;
                        final updatedCurrentBusRoute =
                            oldCurrentBusRoute.copyWith(
                                busRouteNumber:
                                    int.parse(busRouteNumberController.text));
                        final currentState = context.read<AppCubit>().state;
                        final newState = currentState.copyWith(
                            currentBusRoute: updatedCurrentBusRoute);
                        context.read<AppCubit>().updateState(newState);

                        // 2. update busroutenumber on currentbusroute on firebase
                        final currentBusRouteDocId = context
                            .read<AppCubit>()
                            .state
                            .currentBusRouteFirebaseDocId;
                        final newCurrentBusRouteFromState =
                            context.read<AppCubit>().state.currentBusRoute;
                        updateFirebaseDoc(
                            "busRoutes",
                            currentBusRouteDocId,
                            "busRouteNumber",
                            newCurrentBusRouteFromState.busRouteNumber);

                        // 3. update busroutesnumber on students on firebase
                        updateBusRouteNumberOnStudentsOnFirebase(
                            newCurrentBusRouteFromState, oldCurrentBusRoute);

                        // 4. update busroutenumber on currentschool on state
                        final oldCurrentSchool =
                            context.read<AppCubit>().state.currentSchool;
                        final oldCurrentSchoolRoutesNames =
                            oldCurrentSchool.routesNames;
                        List<String> newCurrentSchoolRoutesNames = [];
                        oldCurrentSchoolRoutesNames.forEach((element) {
                          if (element !=
                              oldCurrentBusRoute.busRouteNumber.toString()) {
                            newCurrentSchoolRoutesNames.add(element);
                          }
                        });
                        newCurrentSchoolRoutesNames.add(
                            newCurrentBusRouteFromState.busRouteNumber
                                .toString());
                        final newCurrentSchool = oldCurrentSchool.copyWith(
                            routesNames: newCurrentSchoolRoutesNames);
                        final oldState = context.read<AppCubit>().state;
                        final newState2 =
                            oldState.copyWith(currentSchool: newCurrentSchool);
                        context.read<AppCubit>().updateState(newState2);

                        // 5. update busroutenumber on currentschool on firebase
                        final currentSchoolDocId = context
                            .read<AppCubit>()
                            .state
                            .currentSchoolFirebaseDocId;
                        updateFirebaseDoc("schools", currentSchoolDocId,
                            "routesNames", newCurrentSchoolRoutesNames);
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
                          final oldCurrentBusRoute =
                              context.read<AppCubit>().state.currentBusRoute;
                          final newCurrentBusRoute =
                              oldCurrentBusRoute.copyWith(
                            schoolName: schoolNameController.text,
                          );
                          final oldState = context.read<AppCubit>().state;
                          final newState = oldState.copyWith(
                              currentBusRoute: newCurrentBusRoute);
                          context.read<AppCubit>().updateState(newState);

                          // 2. update schoolname on busroute on firebase
                          final currentBusRouteDocID = context
                              .read<AppCubit>()
                              .state
                              .currentBusRouteFirebaseDocId;
                          final currentBusRouteSchoolNameFromState = context
                              .read<AppCubit>()
                              .state
                              .currentBusRoute
                              .schoolName;
                          updateFirebaseDoc("busRoutes", currentBusRouteDocID,
                              "schoolName", currentBusRouteSchoolNameFromState);

                          // 3. update schoolname on students on firebase
                          final newCurrentBusRouteFromState =
                              context.read<AppCubit>().state.currentBusRoute;
                          updateSchoolNameOnStudentsOnFirebase(
                              newCurrentBusRouteFromState, oldCurrentBusRoute);

                          // 3.51 update routesnames on current school on state
                          final oldCurrentSchool =
                              context.read<AppCubit>().state.currentSchool;
                          final List<String> NewCurrentSchoolRoutesNames = [];
                          oldCurrentSchool.routesNames.forEach((element) {
                            if (element !=
                                oldCurrentBusRoute.busRouteNumber.toString()) {
                              NewCurrentSchoolRoutesNames.add(element);
                            }
                          });
                          print(NewCurrentSchoolRoutesNames);
                          final newCurrentSchool = oldCurrentSchool.copyWith(
                              routesNames: NewCurrentSchoolRoutesNames);
                          final oldState4 = context.read<AppCubit>().state;
                          final newState4 = oldState4.copyWith(
                              currentSchool: newCurrentSchool);
                          context.read<AppCubit>().updateState(newState4);
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
                              routesNames: [currentBusRouteNumber.toString()]);
                          final oldState2 = context.read<AppCubit>().state;
                          final newState2 =
                              oldState2.copyWith(currentSchool: newSchool);
                          context.read<AppCubit>().updateState(newState2);

                          // 5. update schoolname/new school on firebase
                          final newSchoolFromState =
                              context.read<AppCubit>().state.currentSchool;
                          final newSchoolFromStateJson =
                              newSchoolFromState.toJson();
                          createNewFirebaseDoc(
                              "schools", newSchoolFromStateJson);

                          // 6. clear school firebase doc id on state, for now, when we go back to the school screen, or school list screen
                          final oldState5 = context.read<AppCubit>().state;
                          final newState5 = oldState5.copyWith(
                              currentSchoolFirebaseDocId: "");
                          context.read<AppCubit>().updateState(newState5);
                        } else {
                          // 1. double check if new school name already exists, give eroor if true
                          // 2. if not, then check if in the new school a route with same number exists, er if tr
                          // 3. if not, then update school name on cstudents from both schoolnbus on firebase
                          // 4. remove busroute number from current school on state
                          // 5. remove busroute number from current school on firebase
                          // 6. update currentschool on state to be the one with the right name, fetch from db
                          // 7. update current school on state to have the new busroute number addedto it
                          // 8. update current docid to be for this new school
                          // 9. update this new school on firbase
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
  }
}
