import 'dart:io';

void main() async {
  print('Starting license acceptance...');
  final process = await Process.start('flutter', ['doctor', '--android-licenses']);
  
  // Feed it with 'y' and newlines
  for (int i = 0; i < 20; i++) {
    process.stdin.writeln('y');
  }
  
  final stdout = await process.stdout.transform(SystemEncoding().decoder).join();
  final stderr = await process.stderr.transform(SystemEncoding().decoder).join();
  
  final result = await process.exitCode;
  
  print('Exit code: $result');
  print('Stdout: $stdout');
  print('Stderr: $stderr');
  
  File('license_result.txt').writeAsStringSync('Exit code: $result\nStdout: $stdout\nStderr: $stderr');
}
