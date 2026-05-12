import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabase = SupabaseClient(
    'https://wycbnxuhzemgkfebzfmz.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5Y2JueHVoemVtZ2tmZWJ6Zm16Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5MDE2MzgsImV4cCI6MjA5MjQ3NzYzOH0.Df5rENWQ8_xwd6tNQG4x68sAR_MxZMqb7tsJPDnGoKA',
  );

  try {
    print('Attempting to insert L1_D08...');
    await supabase.from('locations').insert({'name': 'L1_D08'});
    print('Insert successful!');
  } on PostgrestException catch (e) {
    print('PostgrestError: ' + e.message);
    print('Details: ' + e.details.toString());
    print('Hint: ' + e.hint.toString());
  } catch (e) {
    print('General Error: ' + e.toString());
  }
  
  try {
    final response = await supabase.from('locations').select('*').limit(5);
    print('Current rows: ' + response.toString());
  } catch(e) {
    print('Select Error: ' + e.toString());
  }
  
  exit(0);
}
