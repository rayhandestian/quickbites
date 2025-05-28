import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tenant_model.dart';

class TenantProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  // Load tenants from Firestore
  Future<void> loadTenants() async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore.collection('tenants').get();
      
      _tenants = querySnapshot.docs.map((doc) {
        return TenantModel(
          id: doc.id,
          name: doc['name'],
          sellerId: doc['sellerId'],
          description: doc['description'],
        );
      }).toList();
    } catch (e) {
      print('Error loading tenants: $e');
      // If there's an error, use an empty list
      _tenants = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add a new tenant
  Future<void> addTenant(TenantModel tenant) async {
    _isLoading = true;
    notifyListeners();

    try {
      final tenantData = {
        'name': tenant.name,
        'sellerId': tenant.sellerId,
        'description': tenant.description,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      final docRef = await _firestore.collection('tenants').add(tenantData);
      
      // Add to local list with the generated ID
      final newTenant = TenantModel(
        id: docRef.id,
        name: tenant.name,
        sellerId: tenant.sellerId,
        description: tenant.description,
      );
      
      _tenants.add(newTenant);
    } catch (e) {
      print('Error adding tenant: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update a tenant
  Future<void> updateTenant(TenantModel updatedTenant) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('tenants').doc(updatedTenant.id).update({
        'name': updatedTenant.name,
        'description': updatedTenant.description,
      });
      
      // Update in local list
      final index = _tenants.indexWhere((tenant) => tenant.id == updatedTenant.id);
      if (index != -1) {
        _tenants[index] = updatedTenant;
      }
    } catch (e) {
      print('Error updating tenant: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
} 