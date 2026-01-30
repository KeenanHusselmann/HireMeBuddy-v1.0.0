import 'package:supabase_flutter/supabase_flutter.dart';

// Run this to get database stats
void main() async {
  // Initialize Supabase (you'll need to add your credentials)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  final supabase = Supabase.instance.client;

  try {
    // Get provider count
    final providerCount = await supabase
        .from('provider_profiles')
        .select('id')
        .count(CountOption.exact);

    // Get client count
    final clientCount = await supabase
        .from('profiles')
        .select('id')
        .eq('role', 'client')
        .count(CountOption.exact);

    print('Provider Count: $providerCount');
    print('Client Count: $clientCount');
  } catch (e) {
    print('Error: $e');
  }
}
