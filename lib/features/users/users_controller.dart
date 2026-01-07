import 'package:flutter/material.dart';
import 'data/user_model.dart';
import '../../core/services/api_service.dart';

import '../../core/architecture/base_controller.dart';

class UsersController extends BaseController {
  List<User> _allUsers = [];
  List<User> filteredUsers = [];
  // isLoading is inherited from BaseController

  UsersController();

  // API Methods
  Future<User?> checkUser(String email) async {
    User? foundUser;
    
    // We can use safeCall for standardized error handling
    await safeCall(() async {
      final response = await ApiService().get('/check-user-exist', queryParams: { 'email': email });
      
      if (response != null && response['isSuccess'] == true && response['data'] != null) {
        final data = response['data'];
        foundUser = User.fromJson(data);
      } else {
        // If API returns success=false or no data, we might throw or just return null
        // safeCall catches exceptions. If we want to show error:
        throw Exception(response?['message'] ?? 'User not found');
      }
    });

    return foundUser;
  }

  Future<bool> addSubjectToUser(String userId, List<String> subjectIds) async {
    return await safeCall(() async {
      final response = await ApiService().put(
        '/update-subjects-to-user',
        body: { 
          'userId': userId, 
          'subjectIds': subjectIds.map((id) => int.parse(id)).toList() 
        }
      );
      
      if (response == null || response['isSuccess'] != true) {
        throw Exception(response?['message'] ?? 'Failed to add subjects');
      }
    });
  }

  Future<bool> updateDeviceId(String email, String newDeviceId) async {
    return await safeCall(() async {
      final response = await ApiService().put(
        '/change-user-deviceId',
        body: { 'email': email, 'newDeviceId': newDeviceId }
      );
       if (response == null || response['isSuccess'] != true) {
        throw Exception(response?['message'] ?? 'Failed to update device ID');
      }
    });
  }

  // Pagination
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasNextPage = true;
  bool isLoadMoreRunning = false;

  void resetPagination() {
    _currentPage = 1;
    _allUsers = [];
    filteredUsers = [];
    _hasNextPage = true;
  }

  Future<void> fetchUsers({String searchKey = '', bool isLoadMore = false}) async {
    // If loading more, strictly avoid global loading state
    if (isLoadMore) {
      if (isLoading || isLoadMoreRunning || !_hasNextPage) return;
      isLoadMoreRunning = true;
      notifyListeners();

      try {
         await _performFetch(searchKey, isLoadMore: true);
      } catch (e) {
        debugPrint('Error loading more users: $e');
        // Optionally set errorMessage for snackbar without full screen error
      } finally {
        isLoadMoreRunning = false;
        notifyListeners();
      }
    } else {
      // Initial load uses safeCall
      await safeCall(() async {
        resetPagination();
        await _performFetch(searchKey, isLoadMore: false);
      });
    }
  }

  Future<void> _performFetch(String searchKey, {required bool isLoadMore}) async {
    final queryParams = {
        'pageNumber': isLoadMore ? '${_currentPage + 1}' : '1',
        'pageSize': '$_pageSize',
        if (searchKey.isNotEmpty) 'searchKey': searchKey,
    };

    final response = await ApiService().get('/enrolled-users', queryParams: queryParams);

    if (response != null && response['isSuccess'] == true && response['hasData'] == true) {
        final data = response['data'];
        final List usersJson = data['users'] ?? [];
        final List<User> newUsers = usersJson.map((json) => User.fromJson(json)).toList();

        if (isLoadMore) {
          _allUsers.addAll(newUsers);
          _currentPage++;
        } else {
          _allUsers = newUsers;
          _currentPage = 1;
        }
        
        _hasNextPage = data['hasNextPage'] ?? false;
        filteredUsers = List.from(_allUsers);
    } else {
       throw Exception(response?['message'] ?? 'Failed to fetch users');
    }
  }
}
