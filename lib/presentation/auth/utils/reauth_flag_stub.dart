bool readReauthFlag() => _memory;

void writeReauthFlag(bool value) {
  _memory = value;
}

bool _memory = false;
