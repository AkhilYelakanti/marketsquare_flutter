import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Local SQLite database (replaces Room `AppDatabase`). Holds pending orders
/// and the item catalog. Opened lazily and shared app-wide.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'marketsquare.db'),
      version: 4,
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) await _createRefreshMetadata(db);
        if (oldV < 3) await _createBackroom(db);
        if (oldV < 4) await _createMessages(db);
      },
      onCreate: (db, _) async {
        await _createRefreshMetadata(db);
        await _createBackroom(db);
        await _createMessages(db);
        await db.execute('''
          CREATE TABLE pending_orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            storeId TEXT NOT NULL DEFAULT '',
            orderType TEXT NOT NULL DEFAULT '',
            partition TEXT NOT NULL DEFAULT '',
            poNumber TEXT NOT NULL DEFAULT '',
            comments TEXT NOT NULL DEFAULT '',
            deliveryDate TEXT NOT NULL DEFAULT '',
            adDate TEXT NOT NULL DEFAULT '',
            adId TEXT NOT NULL DEFAULT '',
            data1 TEXT NOT NULL DEFAULT '',
            data2 TEXT NOT NULL DEFAULT '',
            data3 TEXT NOT NULL DEFAULT '',
            date1 TEXT NOT NULL DEFAULT '',
            date2 TEXT NOT NULL DEFAULT '',
            status TEXT NOT NULL DEFAULT 'UNSENT',
            linesJson TEXT NOT NULL DEFAULT '[]',
            itemCount INTEGER NOT NULL DEFAULT 0,
            totalQty INTEGER NOT NULL DEFAULT 0,
            totalValue TEXT NOT NULL DEFAULT '0.00',
            totalCube TEXT NOT NULL DEFAULT '0.00',
            createdAt INTEGER NOT NULL DEFAULT 0,
            sentAt INTEGER NOT NULL DEFAULT 0,
            confirmationNumber TEXT NOT NULL DEFAULT ''
          )
        ''');
        // Item catalog. Native stores a dynamic CSV-driven schema; this fixed
        // schema captures the columns the order flow reads. Population comes from
        // the (not-yet-ported) Data Sync download.
        await db.execute('''
          CREATE TABLE items (
            itemNumber TEXT PRIMARY KEY,
            description TEXT NOT NULL DEFAULT '',
            pack TEXT NOT NULL DEFAULT '',
            upc TEXT NOT NULL DEFAULT '0',
            department TEXT NOT NULL DEFAULT '',
            adEffective TEXT NOT NULL DEFAULT '0.00',
            allowance TEXT NOT NULL DEFAULT '0.00',
            cube TEXT NOT NULL DEFAULT '0.00',
            itemCodeMults TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute('CREATE INDEX idx_items_desc ON items(description)');
        await db.execute('CREATE INDEX idx_items_upc ON items(upc)');
      },
    );
  }

  /// Schema metadata for the dynamic item_file_data / inventory_data tables
  /// (port of Room `refresh_metadata`). item_file_data itself is dropped and
  /// recreated on every ingest, so it is not declared here.
  static Future<void> _createRefreshMetadata(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS refresh_metadata (
        tableKey TEXT PRIMARY KEY,
        columnSchemaJson TEXT NOT NULL DEFAULT '[]',
        itemColName TEXT NOT NULL DEFAULT '',
        deptColName TEXT NOT NULL DEFAULT '',
        recordCount INTEGER NOT NULL DEFAULT 0,
        lastUpdated TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  /// Local backroom inventory (port of Room `backroom_inventory`).
  static Future<void> _createBackroom(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS backroom_inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        department TEXT NOT NULL DEFAULT '',
        itemCode TEXT NOT NULL DEFAULT '',
        itemDescription TEXT NOT NULL DEFAULT '',
        quantity INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL DEFAULT 0,
        updatedAt INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_backroom_dept_code ON backroom_inventory(department, itemCode)');
  }

  /// Local messages (port of Room `messages`).
  static Future<void> _createMessages(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        messageKey TEXT PRIMARY KEY,
        notificationId TEXT,
        convId TEXT NOT NULL DEFAULT '',
        chainId TEXT NOT NULL DEFAULT '',
        storeId TEXT NOT NULL DEFAULT '',
        storeName TEXT NOT NULL DEFAULT '',
        address TEXT NOT NULL DEFAULT '',
        messageBody TEXT NOT NULL DEFAULT '',
        contactName TEXT NOT NULL DEFAULT '',
        convStatus TEXT NOT NULL DEFAULT '',
        msgStatus TEXT NOT NULL DEFAULT '',
        lastCommunicationDate TEXT NOT NULL DEFAULT '',
        notificationType TEXT NOT NULL DEFAULT '',
        isRead INTEGER NOT NULL DEFAULT 0,
        receivedAt INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
}
