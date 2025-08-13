// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hậu tố email cho tài khoản nhân viên/quản lý
  // Đảm bảo domain này không trùng với domain email thật
  static const String _employeeEmailSuffix =
      '@sonxemaycantho.employee.com'; // <= HÃY ĐỔI ĐỂ DUY NHẤT

  /// 🔄 Lắng nghe thay đổi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- Các hàm cho Nhân viên/Quản lý (Xác thực bằng SĐT + Mật khẩu tĩnh qua Email Alias) ---

  /// ✅ Đăng ký tài khoản Nhân viên/Quản lý bằng SĐT (làm email alias) và mật khẩu tĩnh
  // ignore: unintended_html_in_doc_comment
  /// Trả về Map<String, dynamic>? chứa thông tin user (UID, fullName, role, phoneNumber, type)
  Future<Map<String, dynamic>?> registerStaffAccount({
    required String phoneNumber,
    required String password,
    required String fullName,
    required String role, // 'manager' hoặc 'staff'
  }) async {
    try {
      // Chuyển đổi số điện thoại thành định dạng email alias
      // Loại bỏ ký tự không phải số và đảm bảo không có +84 nếu số bắt đầu bằng 0
      String cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (cleanedPhoneNumber.startsWith('84')) {
        // Nếu đã có 84 đầu, giữ nguyên
      } else if (cleanedPhoneNumber.startsWith('0')) {
        cleanedPhoneNumber =
            '84${cleanedPhoneNumber.substring(1)}'; // Chuyển 0xxx thành 84xxx
      } else if (cleanedPhoneNumber.startsWith('+84')) {
        cleanedPhoneNumber = cleanedPhoneNumber.substring(3); // Bỏ +84
      }
      final String emailAlias = '$cleanedPhoneNumber$_employeeEmailSuffix';

      // Tạo tài khoản Firebase Auth với email alias và mật khẩu
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailAlias,
            password: password,
          );
      User? user = userCredential.user;

      if (user != null) {
        // Lưu thông tin chi tiết vào collection 'accounts'
        await _firestore.collection('accounts').doc(user.uid).set({
          'fullName': fullName,
          'phoneNumber': phoneNumber, // Lưu số điện thoại gốc
          'emailAlias': emailAlias, // Lưu email alias để dễ tra cứu/quản lý
          'role': role,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'password':
              password, // Vẫn đang lưu plaintext, cần cân nhắc hashing hoặc bỏ nếu không cần thiết
        });

        return {
          'uid': user.uid,
          'phoneNumber': phoneNumber,
          'fullName': fullName,
          'role': role,
          'type': 'staff_manager',
        };
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Số điện thoại này đã được đăng ký.');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception(
        'Đăng ký tài khoản nhân viên thất bại. Vui lòng thử lại.',
      );
    }
    return null;
  }

  /// 🔐 Đăng nhập bằng SĐT (làm email alias) và mật khẩu tĩnh (dành cho Nhân viên/Quản lý)
  // ignore: unintended_html_in_doc_comment
  /// Trả về Map<String, dynamic>? chứa thông tin user (UID, fullName, role, phoneNumber, type)
  Future<Map<String, dynamic>?> signInWithPhoneNumberAndStaticPassword({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      // Chuyển đổi số điện thoại thành định dạng email alias để đăng nhập Firebase Auth
      String cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (cleanedPhoneNumber.startsWith('84')) {
        // Nếu đã có 84 đầu, giữ nguyên
      } else if (cleanedPhoneNumber.startsWith('0')) {
        cleanedPhoneNumber =
            '84${cleanedPhoneNumber.substring(1)}'; // Chuyển 0xxx thành 84xxx
      } else if (cleanedPhoneNumber.startsWith('+84')) {
        cleanedPhoneNumber = cleanedPhoneNumber.substring(3); // Bỏ +84
      }
      final String emailAlias = '$cleanedPhoneNumber$_employeeEmailSuffix';

      // Đăng nhập Firebase Auth bằng email alias và mật khẩu
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailAlias,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Lấy dữ liệu người dùng từ collection 'accounts' để kiểm tra vai trò và trạng thái
        DocumentSnapshot userDoc = await _firestore
            .collection('accounts')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          // Kiểm tra trạng thái kích hoạt (isActive)
          if (userData['isActive'] == false) {
            await _auth
                .signOut(); // Đảm bảo người dùng bị đăng xuất nếu không active
            throw Exception('Tài khoản của bạn đã bị vô hiệu hóa.');
          }

          return {
            'uid': user.uid,
            'phoneNumber': userData['phoneNumber'], // Trả về số điện thoại gốc
            'fullName': userData['fullName'],
            'role': userData['role'],
            'type': 'staff_manager',
          };
        } else {
          // Trường hợp user tồn tại trong Firebase Auth (qua email alias) nhưng không có trong Firestore 'accounts'
          // Có thể là do lỗi tạo hoặc xóa thủ công trong Firebase Auth mà không xóa Firestore
          await _auth.signOut();
          throw Exception(
            'Không tìm thấy thông tin tài khoản nhân viên/quản lý. Vui lòng liên hệ quản trị viên.',
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw Exception('Số điện thoại hoặc mật khẩu không đúng.');
      }
      if (e.code == 'too-many-requests') {
        throw Exception(
          'Bạn đã thử đăng nhập quá nhiều lần. Vui lòng thử lại sau.',
        );
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Đăng nhập thất bại. Vui lòng thử lại.');
    }
    return null;
  }

  // --- Các hàm cho Khách hàng (Đăng nhập bằng Google) ---

  /// 🔐 Đăng nhập bằng Google (dành cho Khách hàng)
  // ignore: unintended_html_in_doc_comment
  /// Trả về Map<String, dynamic>? chứa thông tin user (UID, email, fullName, type)
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Người dùng hủy đăng nhập

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Kiểm tra/Lưu thông tin Khách hàng vào collection 'users'
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // Người dùng Google mới, lưu thông tin vào 'users' collection
          await _firestore.collection('users').doc(user.uid).set({
            'fullName':
                user.displayName ??
                user.email?.split('@')[0] ??
                'Khách hàng Google',
            'email': user.email ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true, // Mặc định là active
          });
          return {
            'uid': user.uid,
            'email': user.email,
            'fullName': user.displayName,
            'type': 'customer',
          };
        } else {
          // Khách hàng Google đã tồn tại, kiểm tra isActive
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          if (userData['isActive'] == false) {
            await _auth
                .signOut(); // Đảm bảo người dùng bị đăng xuất nếu không active
            throw Exception('Tài khoản khách hàng của bạn đã bị vô hiệu hóa.');
          }
          return {
            'uid': user.uid,
            'email': user.email,
            'fullName': userData['fullName'],
            'type': 'customer',
          };
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
          'Tài khoản này đã tồn tại với một phương thức đăng nhập khác. Vui lòng sử dụng phương thức đăng nhập ban đầu của bạn.',
        );
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Đăng nhập với Google thất bại.');
    }
    return null;
  }

  /// 🚪 Đăng xuất
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Đăng xuất thất bại.');
    }
  }

  /// 🔑 Đổi mật khẩu cho user hiện tại (dành cho Nhân viên và Quản lý)
  /// Sử dụng updatePassword() của Firebase Auth vì tài khoản là Email/Password.
  /// Cần reauthenticate nếu chưa đăng nhập gần đây.
  /// LƯU Ý: Phương thức này vẫn dựa trên Email Alias và mật khẩu hiện tại.
  /// Nếu bạn muốn đổi mật khẩu bằng OTP cho tài khoản nhân viên/quản lý,
  /// bạn sẽ cần sử dụng luồng OTP để re-authenticate người dùng,
  /// sau đó gọi `user.updatePassword(newPassword)`.
  Future<void> updateUserPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('Không có người dùng nào đang đăng nhập.');
    }

    // Lấy email alias của user từ Firestore
    DocumentSnapshot accountDoc = await _firestore
        .collection('accounts')
        .doc(user.uid)
        .get();

    if (!accountDoc.exists) {
      throw Exception(
        'Không tìm thấy thông tin tài khoản nhân viên/quản lý. Vui lòng liên hệ quản trị viên.',
      );
    }

    Map<String, dynamic> userData = accountDoc.data() as Map<String, dynamic>;
    String? emailAlias = userData['emailAlias'];

    if (emailAlias == null) {
      throw Exception('Không tìm thấy email liên kết cho tài khoản này.');
    }

    try {
      // Re-authenticate người dùng để đảm bảo bảo mật trước khi đổi mật khẩu
      AuthCredential credential = EmailAuthProvider.credential(
        email: emailAlias,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Cập nhật mật khẩu trong Firebase Authentication
      await user.updatePassword(newPassword);

      // Cập nhật mật khẩu tĩnh trong Firestore (Nếu bạn vẫn muốn lưu mật khẩu trong Firestore)
      // Cảnh báo: Việc lưu mật khẩu plaintext trong Firestore là KHÔNG BẢO MẬT.
      // Chỉ nên làm điều này nếu bạn CÓ LÝ DO RÕ RÀNG và bạn sẽ HASH MẬT KHẨU NÀY AN TOÀN.
      // Nếu không, hãy XÓA dòng này và chỉ dựa vào Firebase Auth cho mật khẩu.
      await _firestore.collection('accounts').doc(user.uid).update({
        'password': newPassword,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Mật khẩu hiện tại không đúng.');
      } else if (e.code == 'requires-recent-login') {
        throw Exception(
          'Để thay đổi mật khẩu, bạn cần đăng nhập lại. Vui lòng đăng xuất và đăng nhập lại.',
        );
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Không thể cập nhật mật khẩu. Vui lòng thử lại.');
    }
  }

  /// Phương thức để gửi OTP đến số điện thoại
  /// Đây là phương thức cần thiết cho ChangePasswordScreen với luồng OTP
  Future<void> sendOtpToPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60), // Thời gian chờ mặc định cho OTP
    );
  }

  // Hàm gửi email đặt lại mật khẩu cho tài khoản nhân viên/quản lý (Email Alias)
  Future<void> sendPasswordResetEmailForStaff(String phoneNumber) async {
    String cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanedPhoneNumber.startsWith('84')) {
      // Nếu đã có 84 đầu, giữ nguyên
    } else if (cleanedPhoneNumber.startsWith('0')) {
      cleanedPhoneNumber =
          // ignore: prefer_interpolation_to_compose_strings
          '84' + cleanedPhoneNumber.substring(1); // Chuyển 0xxx thành 84xxx
    } else if (cleanedPhoneNumber.startsWith('+84')) {
      cleanedPhoneNumber = cleanedPhoneNumber.substring(3); // Bỏ +84
    }
    final String emailAlias = '$cleanedPhoneNumber$_employeeEmailSuffix';

    try {
      await _auth.sendPasswordResetEmail(email: emailAlias);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Không tìm thấy tài khoản với số điện thoại này.');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gửi yêu cầu đặt lại mật khẩu thất bại.');
    }
  }

  /// 👤 Lấy người dùng hiện tại từ Firebase Auth
  User? get currentUser => _auth.currentUser;

  /// Lấy thông tin chi tiết người dùng từ Firestore (bao gồm role và type)
  // ignore: unintended_html_in_doc_comment
  /// Trả về Map<String, dynamic>? chứa thông tin chi tiết của user
  Future<Map<String, dynamic>?> getCurrentUserFirestoreData() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    // Kiểm tra trong collection 'accounts' (Nhân viên/Quản lý)
    DocumentSnapshot accountDoc = await _firestore
        .collection('accounts')
        .doc(user.uid)
        .get();
    if (accountDoc.exists) {
      Map<String, dynamic> data = accountDoc.data() as Map<String, dynamic>;
      data['type'] = 'staff_manager'; // Thêm loại người dùng
      return data;
    }

    // Kiểm tra trong collection 'users' (Khách hàng)
    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      data['type'] = 'customer'; // Thêm loại người dùng
      return data;
    }

    // Nếu không tìm thấy ở cả hai nơi
    return null;
  }
}
