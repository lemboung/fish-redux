class Track {
  final List<Pin> _pins = <Pin>[];

  Track();

  factory Track.tags(List<String> tags) {
    tags ??= <String>[];

    final Track tracer = Track();
    for (String tag in tags) {
      tracer.append(tag);
    }

    return tracer;
  }

  factory Track.pins(List<Pin> tags) {
    tags ??= <Pin>[];

    final Track tracer = Track();
    for (Pin pin in tags) {
      tracer.append(pin.tag, pin.value);
    }

    return tracer;
  }

  void append(String tag, [Object value]) {
    _pins.add(Pin(tag, value));
  }

  int countOfTag(String tag) =>
      _pins.fold<int>(0, (int count, Pin pin) => pin.tag == tag ? count + 1 : count);

  void remove(String tag) => _pins.retainWhere((Pin pin)=>pin.tag == tag);

  @override
  String toString() => _pins
      .map<String>((Pin node) => node.toString())
      .fold<String>('', (String prev, String now) => '$prev\n=>$now');

  @override
  bool operator ==(dynamic other) {
    if (!(other is Track)) return false;

    if (_pins.length != other._pins.length) return false;

    for (int index = 0; index < _pins.length; index++) {
      if (_pins[index] != other._pins[index]) return false;
    }

    return true;
  }

  void reset() {
    _pins.clear();
  }
}

class Pin {
  String tag;
  Object value;
  DateTime timeStamp;

  Pin(this.tag, [Object value])
      : timeStamp = DateTime.now(),
        value = value is Function ? value() : value;

  @override
  String toString() => '$tag<${value.toString()}>';

  @override
  bool operator ==(dynamic other) {
    if (!(other is Pin)) return false;

    return other.tag == tag && other.value == value;
  }
}
