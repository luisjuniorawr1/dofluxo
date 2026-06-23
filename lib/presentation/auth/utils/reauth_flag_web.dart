import 'dart:html' as html;

bool readReauthFlag() {
  return html.window.sessionStorage['dofluxo_force_reauth'] == '1';
}

void writeReauthFlag(bool value) {
  if (value) {
    html.window.sessionStorage['dofluxo_force_reauth'] = '1';
  } else {
    html.window.sessionStorage.remove('dofluxo_force_reauth');
  }
}
