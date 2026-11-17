// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

Uint8List createWav({
  required int sampleRate,
  required List<double> samples,
}) {
  final int numSamples = samples.length;
  final int dataSize = numSamples * 2; // 16-bit mono = 2 bytes per sample
  final int fileSize = 44 + dataSize;
  final ByteData byteData = ByteData(fileSize);

  // RIFF header
  byteData.setUint8(0, 0x52); // 'R'
  byteData.setUint8(1, 0x49); // 'I'
  byteData.setUint8(2, 0x46); // 'F'
  byteData.setUint8(3, 0x46); // 'F'
  byteData.setUint32(4, fileSize - 8, Endian.little);
  byteData.setUint8(8, 0x57);  // 'W'
  byteData.setUint8(9, 0x41);  // 'A'
  byteData.setUint8(10, 0x56); // 'V'
  byteData.setUint8(11, 0x45); // 'E'

  // FMT subchunk
  byteData.setUint8(12, 0x66); // 'f'
  byteData.setUint8(13, 0x6D); // 'm'
  byteData.setUint8(14, 0x74); // 't'
  byteData.setUint8(15, 0x20); // ' '
  byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  byteData.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
  byteData.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
  byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
  byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (SampleRate * 1 * 2)
  byteData.setUint16(32, 2, Endian.little);  // BlockAlign
  byteData.setUint16(34, 16, Endian.little); // BitsPerSample

  // DATA subchunk
  byteData.setUint8(36, 0x64); // 'd'
  byteData.setUint8(37, 0x61); // 'a'
  byteData.setUint8(38, 0x74); // 't'
  byteData.setUint8(39, 0x61); // 'a'
  byteData.setUint32(40, dataSize, Endian.little);

  for (int i = 0; i < numSamples; i++) {
    // Clamping sample to [-1.0, 1.0] and convert to 16-bit signed integer
    final double s = samples[i].clamp(-1.0, 1.0);
    final int intSample = (s * 32767).round();
    byteData.setInt16(44 + (i * 2), intSample, Endian.little);
  }

  return byteData.buffer.asUint8List();
}

void main() async {
  final Directory dir = Directory('assets/sounds');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  const int sampleRate = 44100;

  // 1. Radar Alert: Dual-tone urgent repeating beeps (880Hz & 1320Hz)
  // Total ~2.5 seconds loopable
  {
    final List<double> samples = [];
    final double duration = 2.4;
    final int total = (duration * sampleRate).toInt();
    for (int i = 0; i < total; i++) {
      final double t = i / sampleRate;
      final double cycle = t % 0.6; // 600ms repeating burst
      double val = 0.0;
      if (cycle < 0.12) {
        val = 0.8 * sin(2 * pi * 880 * t) + 0.4 * sin(2 * pi * 1760 * t);
      } else if (cycle >= 0.16 && cycle < 0.28) {
        val = 0.85 * sin(2 * pi * 1320 * t) + 0.4 * sin(2 * pi * 2640 * t);
      } else if (cycle >= 0.32 && cycle < 0.44) {
        val = 0.9 * sin(2 * pi * 1760 * t) + 0.5 * sin(2 * pi * 3520 * t);
      }
      samples.add(val * 0.7);
    }
    final wav = createWav(sampleRate: sampleRate, samples: samples);
    File('assets/sounds/alarm_radar.wav').writeAsBytesSync(wav);
    print('Generated alarm_radar.wav: ${wav.length} bytes');
  }

  // 2. Transit Chime: Melodic 3-tone commuter arrival chime (C5 - E5 - G5 - C6)
  {
    final List<double> samples = [];
    final double duration = 3.0;
    final int total = (duration * sampleRate).toInt();
    final notes = [
      {'freq': 523.25, 'start': 0.0, 'end': 0.5},   // C5
      {'freq': 659.25, 'start': 0.5, 'end': 1.0},   // E5
      {'freq': 783.99, 'start': 1.0, 'end': 1.5},   // G5
      {'freq': 1046.50, 'start': 1.5, 'end': 2.6},  // C6
    ];
    for (int i = 0; i < total; i++) {
      final double t = i / sampleRate;
      double val = 0.0;
      for (final n in notes) {
        final double start = n['start']!;
        final double end = n['end']!;
        final double freq = n['freq']!;
        if (t >= start && t < end) {
          final double age = t - start;
          final double envelope = exp(-age * 2.5); // smooth decay
          val += sin(2 * pi * freq * t) * envelope;
          // harmonic
          val += 0.3 * sin(2 * pi * (freq * 2) * t) * envelope;
        }
      }
      samples.add(val * 0.7);
    }
    final wav = createWav(sampleRate: sampleRate, samples: samples);
    File('assets/sounds/alarm_transit.wav').writeAsBytesSync(wav);
    print('Generated alarm_transit.wav: ${wav.length} bytes');
  }

  // 3. Loud Siren: Urgent two-tone European ambulance / transit emergency siren (650Hz to 950Hz)
  {
    final List<double> samples = [];
    final double duration = 2.4;
    final int total = (duration * sampleRate).toInt();
    for (int i = 0; i < total; i++) {
      final double t = i / sampleRate;
      final double cycle = t % 1.2;
      final double freq = cycle < 0.6 ? 700.0 : 960.0;
      final double val = 0.8 * sin(2 * pi * freq * t) + 0.3 * sin(2 * pi * (freq * 3) * t);
      samples.add(val * 0.75);
    }
    final wav = createWav(sampleRate: sampleRate, samples: samples);
    File('assets/sounds/alarm_siren.wav').writeAsBytesSync(wav);
    print('Generated alarm_siren.wav: ${wav.length} bytes');
  }

  // 4. Acoustic Bell: Piercing waking bell strike
  {
    final List<double> samples = [];
    final double duration = 2.5;
    final int total = (duration * sampleRate).toInt();
    for (int i = 0; i < total; i++) {
      final double t = i / sampleRate;
      final double strike = t - (t ~/ 0.8) * 0.8;
      final double decay = exp(-strike * 6.0);
      final double val = (sin(2 * pi * 1200 * t) + 0.5 * sin(2 * pi * 2400 * t) + 0.25 * sin(2 * pi * 3600 * t)) * decay;
      samples.add(val * 0.8);
    }
    final wav = createWav(sampleRate: sampleRate, samples: samples);
    File('assets/sounds/alarm_bell.wav').writeAsBytesSync(wav);
    print('Generated alarm_bell.wav: ${wav.length} bytes');
  }

  print('All alarm sounds generated successfully.');
}
