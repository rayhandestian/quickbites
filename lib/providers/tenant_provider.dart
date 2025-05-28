import 'package:flutter/material.dart';
import '../models/tenant_model.dart';
import '../services/mock_data_service.dart';

class TenantProvider with ChangeNotifier {
  List<TenantModel> _tenants = [];
  bool _isLoading = false;

  List<TenantModel> get tenants => _tenants;
  bool get isLoading => _isLoading;

  // Get a single tenant by ID
  TenantModel? getTenantById(String tenantId) {
    try {
      return _tenants.firstWhere((tenant) => tenant.id == tenantId);
    } catch (e) {
      return null;
    }
  }

  // Get a tenant by seller ID
  TenantModel? getTenantBySellerId(String sellerId) {
    try {
      return _tenants.firstWhere((tenant) => tenant.sellerId == sellerId);
    } catch (e) {
      return null;
    }
  }

  // Load tenants from mock data
  Future<void> loadTenants() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Load mock data
    _tenants = MockDataService.getMockTenants();

    _isLoading = false;
    notifyListeners();
  }

  // Add a new tenant
  Future<void> addTenant(TenantModel tenant) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Add to list
    _tenants.add(tenant);

    _isLoading = false;
    notifyListeners();
  }

  // Update a tenant
  Future<void> updateTenant(TenantModel updatedTenant) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Find and update tenant
    final index = _tenants.indexWhere((tenant) => tenant.id == updatedTenant.id);
    if (index != -1) {
      _tenants[index] = updatedTenant;
    }

    _isLoading = false;
    notifyListeners();
  }
} 