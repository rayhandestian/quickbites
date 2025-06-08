import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/menu_model.dart';
import '../../models/tenant_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/image_helper.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final menuProvider = Provider.of<MenuProvider>(context);
    final tenantProvider = Provider.of<TenantProvider>(context);
    
    if (authService.currentUser == null) {
      return const Center(
        child: Text('Silakan login untuk mengelola inventori'),
      );
    }
    
    // Get seller's tenant
    final tenant = tenantProvider.getTenantBySellerId(authService.currentUser!.id);
    
    if (tenant == null) {
      return const Center(
        child: Text('Tenant tidak ditemukan'),
      );
    }
    
    // Get seller's menu items
    final menuItems = menuProvider.getMenusByTenant(tenant.id);
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add New Menu Button
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Tambah Menu Baru',
                    onPressed: () {
                      _showAddMenuDialog(context, tenant);
                    },
                    icon: Icons.add,
                  ),
                ),
                const SizedBox(width: 8),
                // Test Upload Button (temporary)
                ElevatedButton.icon(
                  onPressed: () => _testCloudinaryUpload(context),
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Test Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Menu List
            const Text(
              'Daftar Menu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            if (menuItems.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('Belum ada menu'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final menu = menuItems[index];
                  return _buildMenuCard(context, menu, tenant);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuCard(BuildContext context, MenuModel menu, TenantModel tenant) {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Menu Image (with Cloudinary image if available)
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: menu.imageUrl != null && menu.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: menu.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            debugPrint('Error loading menu image: $error');
                            return Center(
                              child: Icon(
                                menu.category == FoodCategories.food ? Icons.lunch_dining : Icons.local_drink,
                                size: 35,
                                color: AppColors.primaryAccent,
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          menu.category == FoodCategories.food ? Icons.lunch_dining : Icons.local_drink,
                          size: 35,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency(menu.price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: menu.category == FoodCategories.food 
                                  ? Colors.orange.withOpacity(0.2) 
                                  : Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              menu.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: menu.category == FoodCategories.food 
                                    ? Colors.orange 
                                    : Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: menu.stock > 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Stok: ${menu.stock}',
                              style: TextStyle(
                                fontSize: 12,
                                color: menu.stock > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primaryAccent),
                      onPressed: () {
                        _showEditMenuDialog(context, menu, tenant);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmation(context, menu);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Show image picker dialog with camera and gallery options
  void _showAddMenuDialog(BuildContext context, TenantModel tenant) {
    showDialog(
      context: context,
      builder: (context) => _AddMenuDialog(tenant: tenant),
    );
  }
  
  void _showEditMenuDialog(BuildContext context, MenuModel menu, TenantModel tenant) {
    try {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return _EditMenuDialog(menu: menu, tenant: tenant);
        },
      ).catchError((error) {
        debugPrint('Error showing edit menu dialog: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open edit dialog: $error')),
        );
      });
    } catch (e) {
      debugPrint('Exception when showing edit menu dialog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open edit dialog: $e')),
      );
    }
  }
  
  void _showDeleteConfirmation(BuildContext context, MenuModel menu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Menu'),
        content: Text('Apakah Anda yakin ingin menghapus menu "${menu.name}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final menuProvider = Provider.of<MenuProvider>(context, listen: false);
              menuProvider.deleteMenu(menu.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
  
  // Test function to directly test Cloudinary upload
  Future<void> _testCloudinaryUpload(BuildContext context) async {
    try {
      debugPrint('Starting direct Cloudinary upload test...');
      
      // Show status dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Testing Upload'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Testing Cloudinary upload...\nCheck console for details.'),
            ],
          ),
        ),
      );
      
      // Select an image
      final File? imageFile = await ImageHelper.pickImageFromGallery(
        maxWidth: 800,
        quality: 80,
      );
      
      if (imageFile == null) {
        debugPrint('No image selected for test upload');
        Navigator.pop(context); // Close the status dialog
        
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Test Failed'),
            content: const Text('No image was selected.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      
      debugPrint('Test image selected: ${imageFile.path}');
      
      // Try direct upload
      final cloudinaryService = CloudinaryService();
      final uploadUrl = await cloudinaryService.uploadTestImage(imageFile);
      
      // Close the status dialog
      Navigator.pop(context);
      
      // Show result dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(uploadUrl != null ? 'Upload Test Success' : 'Upload Test Failed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(uploadUrl != null 
                ? 'Image uploaded successfully!' 
                : 'Failed to upload image. Check console logs for details.'
              ),
              if (uploadUrl != null) ...[
                const SizedBox(height: 16),
                const Text('Image Preview:'),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: uploadUrl,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, error, stackTrace) => 
                        const Icon(Icons.error, color: Colors.red, size: 50),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
      debugPrint('Test upload completed with result: ${uploadUrl ?? 'FAILED'}');
    } catch (e) {
      debugPrint('Error in test upload: $e');
      Navigator.of(context).pop(); // Close any open dialogs
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test Error'),
          content: Text('Error: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

// Separate stateful widget for Add Menu Dialog
class _AddMenuDialog extends StatefulWidget {
  final TenantModel tenant;
  
  const _AddMenuDialog({required this.tenant});
  
  @override
  _AddMenuDialogState createState() => _AddMenuDialogState();
}

class _AddMenuDialogState extends State<_AddMenuDialog> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  String selectedCategory = FoodCategories.food;
  File? selectedImage;
  bool isUploading = false;
  
  @override
  void initState() {
    super.initState();
    debugPrint('_AddMenuDialogState initialized');
  }
  
  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    debugPrint('Attempting to pick image for new menu');
    
    if (!mounted) {
      debugPrint('Widget not mounted, aborting image pick');
      return;
    }
    
    try {
      final File? pickedImage = await ImageHelper.showImagePickerDialog(context);
      
      if (pickedImage != null && mounted) {
        // Verify file exists and has data
        if (await pickedImage.exists() && await pickedImage.length() > 0) {
          debugPrint('Image selected successfully: ${pickedImage.path}');
          debugPrint('File size: ${await pickedImage.length()} bytes');
          
          setState(() {
            selectedImage = pickedImage;
          });
          
          // Force UI refresh
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {});
              }
            });
          }
        } else {
          debugPrint('Selected file is invalid or empty');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected image is invalid')),
          );
        }
      } else {
        debugPrint('No image selected or widget no longer mounted');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }
  
  Future<void> _saveMenu() async {
    debugPrint('=== ADDING NEW MENU ===');
    
    if (!mounted) {
      debugPrint('Widget no longer mounted, aborting save');
      return;
    }
    
    final name = nameController.text.trim();
    final priceText = priceController.text.trim();
    final stockText = stockController.text.trim();
    
    if (name.isEmpty || priceText.isEmpty || stockText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    
    final price = int.tryParse(priceText);
    final stock = int.tryParse(stockText);
    
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }
    
    if (stock == null || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid stock')),
      );
      return;
    }
    
    // Show loading dialog
    if (mounted) {
      setState(() {
        isUploading = true;
      });
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text('Adding Menu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(selectedImage != null 
                  ? 'Uploading image and creating menu...' 
                  : 'Creating new menu...'
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    try {
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);
      final tenantId = widget.tenant.id;
      
      // Create new menu object
      final newMenu = MenuModel(
        id: '', // Will be assigned by Firestore
        name: name,
        price: price,
        stock: stock,
        tenantId: tenantId,
        category: selectedCategory,
      );
      
      // Keep reference to image file to avoid state changes
      final imageToUpload = selectedImage;
      
      // Check if we have an image to upload
      final hasImageToUpload = imageToUpload != null && await imageToUpload.exists();
      
      if (hasImageToUpload) {
        debugPrint('Image selected for upload: ${imageToUpload.path}');
        debugPrint('File size: ${await imageToUpload.length()} bytes');
      } else {
        debugPrint('No image selected for upload');
      }
      
      // Add menu with image if selected
      await menuProvider.addMenu(newMenu, imageFile: hasImageToUpload ? imageToUpload : null);
      
      // Close loading dialog and the add menu dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pop(); // Close add menu dialog
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Menu added successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                if (hasImageToUpload) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Image has been uploaded.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding menu: $e');
      
      // Close loading dialog if still mounted
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to add menu: ${e.toString()}',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() {
        isUploading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Menu Baru'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Selection Area
            GestureDetector(
              onTap: isUploading ? null : _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
                ),
                child: selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Error displaying image: $error');
                                return const Center(
                                  child: Icon(Icons.error, color: Colors.red, size: 40),
                                );
                              },
                            ),
                          ),
                          // Add a subtle overlay for better text readability if needed
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Tap to change image',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_a_photo,
                            size: 32,
                            color: AppColors.primaryAccent,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tambah Foto Menu',
                            style: TextStyle(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Nama Menu',
              hintText: 'Masukkan nama menu',
              controller: nameController,
              enabled: !isUploading,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Harga',
              hintText: 'Masukkan harga',
              controller: priceController,
              keyboardType: TextInputType.number,
              enabled: !isUploading,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Stok',
              hintText: 'Masukkan jumlah stok',
              controller: stockController,
              keyboardType: TextInputType.number,
              enabled: !isUploading,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Makanan'),
                        value: FoodCategories.food,
                        groupValue: selectedCategory,
                        onChanged: isUploading ? null : (value) {
                          if (value != null) {
                            setState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Minuman'),
                        value: FoodCategories.beverage,
                        groupValue: selectedCategory,
                        onChanged: isUploading ? null : (value) {
                          if (value != null) {
                            setState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isUploading ? null : () {
            Navigator.pop(context);
          },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: isUploading ? null : _saveMenu,
          child: isUploading 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

// Separate stateful widget for Edit Menu Dialog
class _EditMenuDialog extends StatefulWidget {
  final MenuModel menu;
  final TenantModel tenant;

  const _EditMenuDialog({
    required this.menu,
    required this.tenant,
  });

  @override
  State<_EditMenuDialog> createState() => _EditMenuDialogState();
}

class _EditMenuDialogState extends State<_EditMenuDialog> {
  late final TextEditingController nameController;
  late final TextEditingController priceController;
  late final TextEditingController stockController;
  late String selectedCategory;
  
  // Simple image state - no confusing flags
  File? newImageFile;
  bool isUploading = false;
  
  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.menu.name);
    priceController = TextEditingController(text: widget.menu.price.toString());
    stockController = TextEditingController(text: widget.menu.stock.toString());
    selectedCategory = widget.menu.category;
    
    debugPrint('=== EDIT MENU DIALOG INITIALIZED ===');
    debugPrint('Menu: ${widget.menu.name}');
    debugPrint('Current imageUrl: ${widget.menu.imageUrl ?? "none"}');
  }
  
  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    debugPrint('=== PICKING NEW IMAGE ===');
    
    if (!mounted) {
      debugPrint('Widget not mounted, aborting image pick');
      return;
    }
    
    try {
      final File? pickedImage = await ImageHelper.showImagePickerDialog(context);
      
      if (pickedImage != null && mounted) {
        debugPrint('✅ NEW IMAGE SELECTED: ${pickedImage.path}');
        
        // Verify file exists and has data
        if (await pickedImage.exists() && await pickedImage.length() > 0) {
          debugPrint('File size: ${await pickedImage.length()} bytes');
          
          setState(() {
            newImageFile = pickedImage;
          });
          
          // Force UI refresh
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {});
              }
            });
          }
        } else {
          debugPrint('❌ Selected file is invalid or empty');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected image is invalid')),
          );
        }
      } else {
        debugPrint('❌ No image selected or widget no longer mounted');
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }
  
  void _removeImage() {
    debugPrint('=== REMOVING SELECTED IMAGE ===');
    if (mounted) {
      setState(() {
        newImageFile = null;
      });
    }
  }
  
  Future<void> _saveMenu() async {
    debugPrint('=== SAVING MENU ===');
    
    if (!mounted) {
      debugPrint('Widget no longer mounted, aborting save');
      return;
    }
    
    final name = nameController.text.trim();
    final priceText = priceController.text.trim();
    final stockText = stockController.text.trim();
    
    if (name.isEmpty || priceText.isEmpty || stockText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    
    final price = int.tryParse(priceText);
    final stock = int.tryParse(stockText);
    
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }
    
    if (stock == null || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid stock')),
      );
      return;
    }
    
    // Show loading
    if (mounted) {
      setState(() {
        isUploading = true;
      });
    
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text('Updating Menu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(newImageFile != null 
                  ? 'Uploading image and updating menu...' 
                  : 'Updating menu information...'
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    try {
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);
      
      // Create updated menu with current values
      final updatedMenu = widget.menu.copyWith(
        name: name,
        price: price,
        stock: stock,
        category: selectedCategory,
        // Keep the existing imageUrl to avoid losing it if no new image
        imageUrl: widget.menu.imageUrl,
      );
      
      // Simple logic: if we have a new image, upload it
      debugPrint('=== UPLOAD DECISION ===');
      
      // Capture the file reference to avoid state changes during async operations
      final fileToUpload = newImageFile;
      bool hasNewImage = false;
      
      // Check if there's a new image file
      if (fileToUpload != null) {
        try {
          hasNewImage = await fileToUpload.exists();
          if (hasNewImage) {
            debugPrint('🚀 UPLOADING NEW IMAGE: ${fileToUpload.path}');
            debugPrint('File size: ${await fileToUpload.length()} bytes');
          } else {
            debugPrint('❌ File does not exist: ${fileToUpload.path}');
          }
        } catch (e) {
          debugPrint('❌ Error checking if file exists: $e');
          hasNewImage = false;
        }
      } else {
        debugPrint('📝 NO NEW IMAGE - keeping existing');
      }
      
      // Update menu - pass the new image file if we have one
      await menuProvider.updateMenu(
        updatedMenu,
        imageFile: hasNewImage ? fileToUpload : null, // Only pass the file if it exists
      );
      
      debugPrint('✅ MENU UPDATE COMPLETED');
      
      // Close dialogs only if still mounted
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pop(); // Close edit dialog
        
        // Show success dialog instead of snackbar
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Menu updated successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                if (hasNewImage) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'New image has been uploaded.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      debugPrint('❌ ERROR UPDATING MENU: $e');
      
      // Close loading dialog only if still mounted
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show error dialog instead of snackbar
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to update menu: ${e.toString()}',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      // Update state only if still mounted, regardless of success/failure
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Menu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image section
            GestureDetector(
              onTap: isUploading ? null : _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.5)),
                ),
                child: newImageFile != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              newImageFile!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Error loading image: $error');
                                return const Center(
                                  child: Icon(Icons.error, color: Colors.red, size: 40),
                                );
                              },
                            ),
                          ),
                          // Add a subtle overlay for better text readability
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Tap to change image',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      )
                    : widget.menu.imageUrl != null && widget.menu.imageUrl!.isNotEmpty
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: widget.menu.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, error, stackTrace) {
                                    debugPrint('Error loading network image: $error');
                                    return const Center(
                                      child: Icon(Icons.error, color: Colors.red, size: 40),
                                    );
                                  },
                                ),
                              ),
                              // Add a subtle overlay for better text readability
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Tap to change image',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_photo_alternate, size: 40, color: AppColors.primaryAccent),
                              SizedBox(height: 8),
                              Text(
                                'Add Menu Image',
                                style: TextStyle(
                                  color: AppColors.primaryAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            
            if (widget.menu.imageUrl != null || newImageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: isUploading ? null : () {
                        setState(() {
                          newImageFile = null;
                        });
                      },
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            AppTextField(
              controller: nameController,
              label: 'Menu Name',
              enabled: !isUploading,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: priceController,
              label: 'Price',
              keyboardType: TextInputType.number,
              enabled: !isUploading,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: stockController,
              label: 'Stock',
              keyboardType: TextInputType.number,
              enabled: !isUploading,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                FoodCategories.food,
                FoodCategories.beverage,
              ].map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: isUploading ? null : (String? value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isUploading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isUploading ? null : _saveMenu,
          child: isUploading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
} 