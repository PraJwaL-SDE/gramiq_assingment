import 'base_view_model.dart';

class HomeViewModel extends BaseViewModel {
  String _title = "Welcome to Gramiq";
  String get title => _title;

  void updateTitle(String newTitle) {
    _title = newTitle;
    notifyListeners();
  }
}
