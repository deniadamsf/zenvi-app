import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('zenvi_pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 10, // Upgraded version for Point Redemption support
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE local_products ADD COLUMN company_id INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE local_products ADD COLUMN image_url TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE local_products ADD COLUMN discount_nominal REAL DEFAULT 0');
      await db.execute('ALTER TABLE local_products ADD COLUMN discount_percent REAL DEFAULT 0');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE local_products ADD COLUMN variants_json TEXT');
      await db.execute('ALTER TABLE offline_order_items ADD COLUMN variant_name TEXT');
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE offline_orders ADD COLUMN payment_method TEXT DEFAULT 'cash'");
      await db.execute("ALTER TABLE offline_orders ADD COLUMN cash_received REAL DEFAULT 0");
      await db.execute("ALTER TABLE offline_orders ADD COLUMN cash_change REAL DEFAULT 0");
    }
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE offline_orders ADD COLUMN company_id INTEGER");
      await db.execute("ALTER TABLE offline_orders ADD COLUMN user_id INTEGER");
    }
    if (oldVersion < 7) {
      await db.execute("ALTER TABLE local_products ADD COLUMN category TEXT");
    }
    if (oldVersion < 8) {
      await db.execute("ALTER TABLE offline_orders ADD COLUMN serviced_by_user_id INTEGER");
      await db.execute("ALTER TABLE offline_orders ADD COLUMN serviced_by_name TEXT");
    }
    if (oldVersion < 9) {
      await db.execute("ALTER TABLE offline_orders ADD COLUMN member_id INTEGER");
      await db.execute("ALTER TABLE offline_orders ADD COLUMN member_name TEXT");
      await db.execute("ALTER TABLE offline_orders ADD COLUMN member_phone TEXT");
      await db.execute("ALTER TABLE offline_orders ADD COLUMN member_discount_amount REAL DEFAULT 0");

      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_members (
          id INTEGER PRIMARY KEY,
          company_id INTEGER DEFAULT 0,
          member_code TEXT,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          email TEXT,
          address TEXT,
          birth_date TEXT,
          points INTEGER DEFAULT 0,
          total_spend REAL DEFAULT 0,
          total_transactions INTEGER DEFAULT 0,
          custom_discount_percent REAL DEFAULT 0,
          is_active INTEGER DEFAULT 1,
          notes TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_member_promos (
          id INTEGER PRIMARY KEY,
          company_id INTEGER DEFAULT 0,
          name TEXT NOT NULL,
          description TEXT,
          discount_type TEXT NOT NULL,
          discount_value REAL NOT NULL,
          min_purchase REAL DEFAULT 0,
          start_date TEXT,
          end_date TEXT,
          is_active INTEGER DEFAULT 1,
          product_ids_json TEXT
        )
      ''');
    }
    if (oldVersion < 10) {
      await db.execute("ALTER TABLE offline_orders ADD COLUMN points_redeemed INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE offline_orders ADD COLUMN point_redeem_amount REAL DEFAULT 0");
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const integerType = 'INTEGER NOT NULL';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';

    // 1. Tabel Produk Lokal (Sinkronisasi dari Server)
    await db.execute('''
      CREATE TABLE local_products (
        id INTEGER PRIMARY KEY,
        company_id INTEGER DEFAULT 0,
        name $textType,
        category TEXT,
        price $realType,
        is_active INTEGER NOT NULL,
        image_url TEXT,
        discount_nominal REAL DEFAULT 0,
        discount_percent REAL DEFAULT 0,
        variants_json TEXT
      )
    ''');

    // 2. Tabel Order Offline (Menunggu disinkronkan ke server)
    await db.execute('''
      CREATE TABLE offline_orders (
        id $idType,
        shift_id $integerType,
        total_amount $realType,
        payment_method TEXT DEFAULT 'cash',
        cash_received REAL DEFAULT 0,
        cash_change REAL DEFAULT 0,
        company_id INTEGER,
        user_id INTEGER,
        serviced_by_user_id INTEGER,
        serviced_by_name TEXT,
        member_id INTEGER,
        member_name TEXT,
        member_phone TEXT,
        member_discount_amount REAL DEFAULT 0,
        points_redeemed INTEGER DEFAULT 0,
        point_redeem_amount REAL DEFAULT 0,
        created_at $textType
      )
    ''');

    // 3. Tabel Order Items Offline
    await db.execute('''
      CREATE TABLE offline_order_items (
        id $idType,
        offline_order_id $integerType,
        product_id $integerType,
        variant_name TEXT,
        qty $integerType,
        subtotal $realType,
        FOREIGN KEY (offline_order_id) REFERENCES offline_orders (id) ON DELETE CASCADE
      )
    ''');

    // 4. Tabel Member Lokal
    await db.execute('''
      CREATE TABLE local_members (
        id INTEGER PRIMARY KEY,
        company_id INTEGER DEFAULT 0,
        member_code TEXT,
        name $textType,
        phone $textType,
        email TEXT,
        address TEXT,
        birth_date TEXT,
        points INTEGER DEFAULT 0,
        total_spend REAL DEFAULT 0,
        total_transactions INTEGER DEFAULT 0,
        custom_discount_percent REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        notes TEXT
      )
    ''');

    // 5. Tabel Promo Member Lokal
    await db.execute('''
      CREATE TABLE local_member_promos (
        id INTEGER PRIMARY KEY,
        company_id INTEGER DEFAULT 0,
        name $textType,
        description TEXT,
        discount_type $textType,
        discount_value $realType,
        min_purchase REAL DEFAULT 0,
        start_date TEXT,
        end_date TEXT,
        is_active INTEGER DEFAULT 1,
        product_ids_json TEXT
      )
    ''');
  }

  // --- Operasi Produk Lokal ---

  Future<void> syncLocalProducts(List<ProductModel> products) async {
    final db = await instance.database;
    final batch = db.batch();
    
    // Hapus semua data lama agar terganti dengan yang baru (Full Sync)
    batch.delete('local_products');
    
    for (var product in products) {
      batch.insert('local_products', product.toMap());
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<ProductModel>> getLocalProducts() async {
    final db = await instance.database;
    final result = await db.query('local_products', where: 'is_active = ?', whereArgs: [1]);
    return result.map((json) => ProductModel.fromMap(json)).toList();
  }

  // --- Operasi Transaksi (Order) Offline ---

  Future<void> saveOfflineOrder(
    int shiftId, 
    double totalAmount, 
    List<Map<String, dynamic>> items, {
    String paymentMethod = 'cash',
    double? cashReceived,
    double? cashChange,
    int? companyId,
    int? userId,
    int? servicedByUserId,
    String? servicedByName,
    int? memberId,
    String? memberName,
    String? memberPhone,
    double? memberDiscountAmount,
    int? pointsRedeemed,
    double? pointRedeemAmount,
  }) async {
    final db = await instance.database;
    
    await db.transaction((txn) async {
      // 1. Simpan Header Order
      final orderId = await txn.insert('offline_orders', {
        'shift_id': shiftId,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'cash_received': cashReceived ?? totalAmount,
        'cash_change': cashChange ?? 0,
        'company_id': companyId,
        'user_id': userId,
        'serviced_by_user_id': servicedByUserId,
        'serviced_by_name': servicedByName,
        'member_id': memberId,
        'member_name': memberName,
        'member_phone': memberPhone,
        'member_discount_amount': memberDiscountAmount ?? 0,
        'points_redeemed': pointsRedeemed ?? 0,
        'point_redeem_amount': pointRedeemAmount ?? 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Potong saldo poin lokal member secara instan jika ada poin yang ditukarkan
      if (memberId != null && (pointsRedeemed ?? 0) > 0) {
        await txn.rawUpdate(
          'UPDATE local_members SET points = CASE WHEN points >= ? THEN points - ? ELSE 0 END WHERE id = ?',
          [pointsRedeemed, pointsRedeemed, memberId],
        );
      }

      // 3. Simpan Detail Items
      for (var item in items) {
        await txn.insert('offline_order_items', {
          'offline_order_id': orderId,
          'product_id': item['product_id'],
          'variant_name': item['variant_name'],
          'qty': item['qty'],
          'subtotal': item['subtotal'],
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedOrders({int? companyId, int? userId}) async {
    final db = await instance.database;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (companyId != null) {
      whereClause += ' AND company_id = ?';
      whereArgs.add(companyId);
    }
    if (userId != null) {
      whereClause += ' AND user_id = ?';
      whereArgs.add(userId);
    }
    
    final orders = await db.query('offline_orders', where: whereClause, whereArgs: whereArgs);
    
    List<Map<String, dynamic>> syncPayload = [];
    
    for (var order in orders) {
      final items = await db.rawQuery('''
        SELECT i.*, p.name as product_name
        FROM offline_order_items i
        LEFT JOIN local_products p ON i.product_id = p.id
        WHERE i.offline_order_id = ?
      ''', [order['id']]);
      
      syncPayload.add({
        'local_id': order['id'], // Digunakan untuk menghapus nanti
        'shift_id': order['shift_id'],
        'total_amount': order['total_amount'],
        'payment_method': order['payment_method'] ?? 'cash',
        'cash_received': order['cash_received'] ?? 0,
        'cash_change': order['cash_change'] ?? 0,
        'serviced_by_user_id': order['serviced_by_user_id'],
        'serviced_by_name': order['serviced_by_name'],
        'member_id': order['member_id'],
        'member_name': order['member_name'],
        'member_phone': order['member_phone'],
        'member_discount_amount': order['member_discount_amount'] ?? 0,
        'points_redeemed': order['points_redeemed'] ?? 0,
        'point_redeem_amount': order['point_redeem_amount'] ?? 0,
        'created_at': order['created_at'],
        'items': items.map((i) {
          final pName = i['product_name'] ?? 'Produk';
          final vName = i['variant_name'];
          final displayName = (vName != null && vName.toString().isNotEmpty) ? '$pName - $vName' : pName.toString();
          return {
            'product_id': i['product_id'],
            'product_name': displayName,
            'variant_name': i['variant_name'],
            'qty': i['qty'],
            'subtotal': i['subtotal'],
          };
        }).toList(),
      });
    }
    
    return syncPayload;
  }

  Future<void> deleteSyncedOrder(int localOrderId) async {
    final db = await instance.database;
    await db.delete('offline_orders', where: 'id = ?', whereArgs: [localOrderId]);
    // items akan otomatis terhapus karena ON DELETE CASCADE
  }

  // --- Operasi Member & Promo Lokal ---

  Future<void> syncLocalMembers(List<Map<String, dynamic>> members) async {
    final db = await instance.database;
    final batch = db.batch();
    batch.delete('local_members');
    for (var member in members) {
      batch.insert('local_members', {
        'id': member['id'],
        'company_id': member['company_id'] ?? 0,
        'member_code': member['member_code'],
        'name': member['name'],
        'phone': member['phone'],
        'email': member['email'],
        'address': member['address'],
        'birth_date': member['birth_date'],
        'points': member['points'] ?? 0,
        'total_spend': (member['total_spend'] as num?)?.toDouble() ?? 0.0,
        'total_transactions': member['total_transactions'] ?? 0,
        'custom_discount_percent': (member['custom_discount_percent'] as num?)?.toDouble() ?? 0.0,
        'is_active': (member['is_active'] == true || member['is_active'] == 1) ? 1 : 0,
        'notes': member['notes'],
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getLocalMembers({String? query}) async {
    final db = await instance.database;
    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      return await db.query(
        'local_members',
        where: 'is_active = 1 AND (name LIKE ? OR phone LIKE ? OR member_code LIKE ?)',
        whereArgs: [q, q, q],
        orderBy: 'name ASC',
      );
    }
    return await db.query('local_members', where: 'is_active = 1', orderBy: 'name ASC');
  }

  Future<void> syncLocalMemberPromos(List<Map<String, dynamic>> promos) async {
    final db = await instance.database;
    final batch = db.batch();
    batch.delete('local_member_promos');
    for (var promo in promos) {
      batch.insert('local_member_promos', {
        'id': promo['id'],
        'company_id': promo['company_id'] ?? 0,
        'name': promo['name'],
        'description': promo['description'],
        'discount_type': promo['discount_type'],
        'discount_value': (promo['discount_value'] as num?)?.toDouble() ?? 0.0,
        'min_purchase': (promo['min_purchase'] as num?)?.toDouble() ?? 0.0,
        'start_date': promo['start_date'],
        'end_date': promo['end_date'],
        'is_active': (promo['is_active'] == true || promo['is_active'] == 1) ? 1 : 0,
        'product_ids_json': promo['product_ids_json'],
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getLocalMemberPromos() async {
    final db = await instance.database;
    return await db.query('local_member_promos', where: 'is_active = 1');
  }
}
