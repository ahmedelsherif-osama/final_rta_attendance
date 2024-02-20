import 'package:final_rta_attendance/cubit/app_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit(super.initialState);

  void updateState(AppState appState) {
    emit(appState);
  }
}
