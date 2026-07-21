import 'dart:html' as html;

String? readLastUid() => html.window.sessionStorage['dofluxo_last_uid'];

String? readLastEmail() => html.window.sessionStorage['dofluxo_last_email'];

void writeLastSession({required String uid, String? email}) {
  html.window.sessionStorage['dofluxo_last_uid'] = uid;
  if (email != null && email.isNotEmpty) {
    html.window.sessionStorage['dofluxo_last_email'] = email;
  } else {
    html.window.sessionStorage.remove('dofluxo_last_email');
  }
}

void clearLastSession() {
  html.window.sessionStorage.remove('dofluxo_last_uid');
  html.window.sessionStorage.remove('dofluxo_last_email');
}
