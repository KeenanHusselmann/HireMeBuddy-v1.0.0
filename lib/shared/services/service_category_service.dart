import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/service_category.dart';

class ServiceCategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all active service categories
  Future<List<ServiceCategory>> getActiveCategories() async {
    final response = await _supabase
        .from('service_categories')
        .select()
        .eq('is_active', true)
        .order('name');

    return (response as List)
        .map((json) => ServiceCategory.fromJson(json))
        .toList();
  }

  // Get all categories (including inactive) - Admin only
  Future<List<ServiceCategory>> getAllCategories() async {
    final response = await _supabase
        .from('service_categories')
        .select()
        .order('name');

    return (response as List)
        .map((json) => ServiceCategory.fromJson(json))
        .toList();
  }

  // Get category by ID
  Future<ServiceCategory?> getCategoryById(String id) async {
    final response = await _supabase
        .from('service_categories')
        .select()
        .eq('id', id)
        .single();

    return ServiceCategory.fromJson(response);
  }

  // Create new category (Admin only)
  Future<ServiceCategory> createCategory({
    required String name,
    required String description,
  }) async {
    final response = await _supabase
        .from('service_categories')
        .insert({
          'name': name,
          'description': description,
          'is_active': true,
        })
        .select()
        .single();

    return ServiceCategory.fromJson(response);
  }

  // Update category (Admin only)
  Future<void> updateCategory({
    required String id,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (isActive != null) updates['is_active'] = isActive;

    await _supabase.from('service_categories').update(updates).eq('id', id);
  }

  // Delete category (Admin only)
  Future<void> deleteCategory(String id) async {
    await _supabase.from('service_categories').delete().eq('id', id);
  }
}
