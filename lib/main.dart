import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String sbUrl = 'https://supabase.co';
const String sbKey = 'sb_publishable_q8Q4n2v9X7kLm3pR6tW1yZ_primorye_anon_key';

void main() => runApp(const PrimoryeDispatchApp());

class PrimoryeDispatchApp extends StatelessWidget {
  const PrimoryeDispatchApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Работа Тут — Диспетчерская (Taxsee Dispatch)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF14171C),
        primaryColor: const Color(0xFFFFCC00),
      ),
      home: const DispatchTerminalScreen(),
    );
  }
}

class DispatchTerminalScreen extends StatefulWidget {
  const DispatchTerminalScreen({super.key});
  @override
  State<DispatchTerminalScreen> createState() => _DispatchTerminalScreenState();
}

class _DispatchTerminalScreenState extends State<DispatchTerminalScreen> {
  bool _loading = false;
  int _rightTab = 0;
  String _selectedCity = 'Артём';
  String _selectedService = 'Грузчики';
  int _workersQty = 2;
  int _hoursQty = 2;

  final _clientPhoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  List<Map<String, dynamic>> _cities = [
    {'city': 'Артём', 'region': 'Приморский край', 'coef': 1.00},
    {'city': 'Владивосток', 'region': 'Приморский край', 'coef': 1.15},
    {'city': 'Уссурийск', 'region': 'Приморский край', 'coef': 1.00},
    {'city': 'Находка', 'region': 'Приморский край', 'coef': 1.05},
    {'city': 'Москва', 'region': 'Москва и МО', 'coef': 1.45},
  ];

  List<Map<String, dynamic>> _services = [
    {'id': 1, 'title': 'Грузчики', 'parent_title': '', 'rate': 750, 'min_hours': 2, 'max_qty': 30, 'sort_order': 1},
    {'id': 2, 'title': 'Грузовое такси', 'parent_title': '', 'rate': 1400, 'min_hours': 2, 'max_qty': 10, 'sort_order': 2},
    {'id': 3, 'title': 'Разнорабочие', 'parent_title': '', 'rate': 650, 'min_hours': 4, 'max_qty': 30, 'sort_order': 3},
    {'id': 4, 'title': 'Клининг / Уборка', 'parent_title': '', 'rate': 900, 'min_hours': 3, 'max_qty': 15, 'sort_order': 4},
    {'id': 5, 'title': 'Спецтехника', 'parent_title': '', 'rate': 3500, 'min_hours': 4, 'max_qty': 5, 'sort_order': 5},
    {'id': 12, 'title': 'Автокран', 'parent_title': 'Спецтехника', 'rate': 4000, 'min_hours': 4, 'max_qty': 3, 'sort_order': 1},
    {'id': 13, 'title': 'Экскаватор-погрузчик', 'parent_title': 'Спецтехника', 'rate': 3500, 'min_hours': 4, 'max_qty': 3, 'sort_order': 2},
    {'id': 14, 'title': 'Манипулятор (воровайка)', 'parent_title': 'Спецтехника', 'rate': 3200, 'min_hours': 3, 'max_qty': 5, 'sort_order': 3},
  ];

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _blacklist = [];

  @override
  void initState() {
    super.initState();
    _clientPhoneCtrl.addListener(() => setState(() {}));
    _syncCloud();
  }

  Map<String, String> get _headers => {
    'apikey': sbKey,
    'Authorization': 'Bearer $sbKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  Future<List<Map<String, dynamic>>> _fetch(String query) async {
    try {
      final r = await html.HttpRequest.request('$sbUrl/rest/v1/$query', method: 'GET', requestHeaders: _headers);
      if (r.status == 200 && r.responseText != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(r.responseText!));
      }
    } catch (_) {}
    return [];
  }

  Future<void> _syncCloud() async {
    setState(() => _loading = true);
    final c = await _fetch('cities?select=*&order=city.asc');
    final s = await _fetch('services?select=*&active=eq.true&order=parent_title.asc,sort_order.asc');
    final o = await _fetch('orders?select=*&order=id.desc');
    final b = await _fetch('blacklist?select=*&order=id.desc');
    setState(() {
      if (c.isNotEmpty) {
        _cities = c;
        if (!_cities.any((x) => x['city'] == _selectedCity)) {
          _selectedCity = _cities.first['city'].toString();
        }
      }
      if (s.isNotEmpty) {
        _services = s;
        if (!_services.any((x) => x['title'] == _selectedService)) {
          _selectedService = _services.first['title'].toString();
        }
      }
      _orders = o;
      _blacklist = b;
      _loading = false;
    });
  }
  Map<String, dynamic> get _currentServiceObj =>
      _services.firstWhere((s) => s['title'] == _selectedService, orElse: () => _services.first);

  double get _currentCityCoef {
    final c = _cities.firstWhere((x) => x['city'] == _selectedCity, orElse: () => {'coef': 1.0});
    return ((c['coef'] ?? 1.0) as num).toDouble();
  }

  int get _calculatedTotal {
    final rate = ((_currentServiceObj['rate'] ?? 750) as num).toInt();
    return (rate * _currentCityCoef * _workersQty * _hoursQty).round();
  }

  Map<String, dynamic>? get _blacklistedMatch {
    final raw = _clientPhoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (raw.length < 6) return null;
    for (final b in _blacklist) {
      final bDigits = (b['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
      if (bDigits.isNotEmpty && (bDigits.contains(raw) || raw.contains(bDigits))) {
        return b;
      }
    }
    return null;
  }

  Future<void> _submitOrder() async {
    if (_addressCtrl.text.trim().isEmpty) return;
    final payload = {
      'service_title': _selectedService,
      'city': _selectedCity,
      'address': _commentCtrl.text.trim().isEmpty
          ? _addressCtrl.text.trim()
          : '${_addressCtrl.text.trim()} (${_commentCtrl.text.trim()})',
      'client_phone': _clientPhoneCtrl.text.trim(),
      'needed_workers': _workersQty,
      'hired_workers': 0,
      'total_sum': _calculatedTotal,
      'status': 'Открыт',
    };
    await html.HttpRequest.request('$sbUrl/rest/v1/orders',
        method: 'POST', requestHeaders: _headers, sendData: jsonEncode(payload));
    _addressCtrl.clear();
    _commentCtrl.clear();
    await _syncCloud();
  }

  Future<void> _addOneWorkerToOrder(Map<String, dynamic> o) async {
    final id = o['id'];
    final hired = ((o['hired_workers'] ?? 0) as int) + 1;
    final need = (o['needed_workers'] ?? 1) as int;
    final isClosed = hired >= need;
    if (id != null) {
      await html.HttpRequest.request(
        '$sbUrl/rest/v1/orders?id=eq.$id',
        method: 'PATCH',
        requestHeaders: _headers,
        sendData: jsonEncode({
          'hired_workers': hired,
          'status': isClosed ? 'Закрыт (набран)' : 'Идёт набор',
        }),
      );
      await _syncCloud();
    }
  }

  void _openWaybillPrintWindow(Map<String, dynamic> o) {
    final win = html.window.open('', 'waybill', 'width=900,height=650');
    final doc = '''
<!DOCTYPE html><html><head><meta charset="utf-8"><title>Маршрутный лист №${o['id']}</title>
<style>body{font-family:Arial,sans-serif;padding:24px}table{width:100%;border-collapse:collapse;margin-top:16px}td,th{border:1px solid #000;padding:8px;text-align:left}</style>
</head><body onload="window.print()">
<h2>МАРШРУТНЫЙ ЛИСТ № ${o['id']}</h2>
<p><b>Перевозчик:</b> ИП Беляков Е. Д. &nbsp;|&nbsp; <b>Автомобиль:</b> ХИНО С 738 СВ 125</p>
<p><b>Город:</b> ${o['city']} &nbsp;|&nbsp; <b>Дата:</b> ${DateTime.now().toString().substring(0, 10)}</p>
<table>
<tr><th>Услуга</th><th>Адрес подачи</th><th>Бригада</th><th>Телефон клиента</th><th>Сумма заказа</th></tr>
<tr><td>${o['service_title']}</td><td>${o['address']}</td><td>${o['needed_workers']} чел.</td><td>${o['client_phone']}</td><td><b>${o['total_sum']} ₽</b></td></tr>
</table>
<p style="margin-top:30px">Диспетчер: _______________ &nbsp;&nbsp;&nbsp; Водитель / Бригадир: _______________ &nbsp;&nbsp;&nbsp; Заказчик: _______________</p>
</body></html>''';
    (win as dynamic).document.write(doc);
    (win as dynamic).document.close();
  }
  @override
  Widget build(BuildContext context) {
    final blHit = _blacklistedMatch;
    final maxAllowed = ((_currentServiceObj['max_qty'] ?? 30) as num).toInt();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCC00),
        foregroundColor: Colors.black,
        title: const Text('РАБОТА ТУТ • ДИСПЕТЧЕРСКАЯ (Taxsee Dispatch)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        actions: [
          TextButton.icon(
            onPressed: _syncCloud,
            icon: const Icon(Icons.sync, color: Colors.black),
            label: Text(_loading ? 'Обновление...' : 'Обновить из облака', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 390,
            color: const Color(0xFF1B1F26),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Новый заказ по телефону', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: const InputDecoration(labelText: 'Город (96 городов в базе)', border: OutlineInputBorder(), isDense: true),
                    items: _cities.map((c) => DropdownMenuItem(value: c['city'].toString(), child: Text('${c['city']} (×${c['coef']})'))).toList(),
                    onChanged: (v) => setState(() => _selectedCity = v ?? _selectedCity),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedService,
                    decoration: const InputDecoration(labelText: 'Услуга / техника', border: OutlineInputBorder(), isDense: true),
                    items: _services.map((s) {
                      final p = (s['parent_title'] ?? '').toString();
                      final label = p.isEmpty ? '${s['title']} (${s['rate']} ₽/ч)' : '$p → ${s['title']} (${s['rate']} ₽/ч)';
                      return DropdownMenuItem(value: s['title'].toString(), child: Text(label, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (v) => setState(() {
                      _selectedService = v ?? _selectedService;
                      final m = ((_currentServiceObj['max_qty'] ?? 30) as num).toInt();
                      if (_workersQty > m) _workersQty = m;
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _clientPhoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'Телефон клиента (+7...)',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      filled: blHit != null,
                      fillColor: blHit != null ? Colors.red.withOpacity(0.25) : null,
                    ),
                  ),
                  if (blHit != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('ВНИМАНИЕ! В ЧЁРНОМ СПИСКЕ: ${blHit['reason']}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  const SizedBox(height: 10),
                  TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Адрес подачи (улица, дом)', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  TextField(controller: _commentCtrl, decoration: const InputDecoration(labelText: 'Примечание (этаж, груз, время)', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Людей / ед. (до $maxAllowed): $_workersQty', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(children: [
                        IconButton(onPressed: _workersQty > 1 ? () => setState(() => _workersQty--) : null, icon: const Icon(Icons.remove_circle_outline)),
                        IconButton(onPressed: _workersQty < maxAllowed ? () => setState(() => _workersQty++) : null, icon: const Icon(Icons.add_circle_outline)),
                      ]),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Часов работы: $_hoursQty', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(children: [
                        IconButton(onPressed: _hoursQty > 1 ? () => setState(() => _hoursQty--) : null, icon: const Icon(Icons.remove_circle_outline)),
                        IconButton(onPressed: () => setState(() => _hoursQty++), icon: const Icon(Icons.add_circle_outline)),
                      ]),
                    ],
                  ),
                  const Divider(),
                  Text('Расчёт с коэф. города: $_calculatedTotal ₽', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFFFCC00))),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00), foregroundColor: Colors.black),
                      onPressed: _submitOrder,
                      icon: const Icon(Icons.send),
                      label: const Text('Отправить заявку в эфир', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: const Color(0xFF1F242D),
                  child: Row(
                    children: [
                      ChoiceChip(label: Text('Активный эфир (${_orders.length})'), selected: _rightTab == 0, onSelected: (_) => setState(() => _rightTab = 0)),
                      const SizedBox(width: 8),
                      ChoiceChip(label: Text('Таблица расценок (${_services.length})'), selected: _rightTab == 1, onSelected: (_) => setState(() => _rightTab = 1)),
                      const SizedBox(width: 8),
                      ChoiceChip(label: Text('Чёрный список (${_blacklist.length})'), selected: _rightTab == 2, onSelected: (_) => setState(() => _rightTab = 2)),
                    ],
                  ),
                ),
                Expanded(
                  child: _rightTab == 0
                      ? _buildOrdersList()
                      : _rightTab == 1
                          ? _buildPricesTable()
                          : _buildBlacklistView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_orders.isEmpty) {
      return const Center(child: Text('Эфир пуст. Оформите заявку слева или примите из мобильного приложения.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _orders.length,
      itemBuilder: (_, i) {
        final o = _orders[i];
        final hired = o['hired_workers'] ?? 0;
        final need = o['needed_workers'] ?? 1;
        final full = hired >= need;
        return Card(
          color: const Color(0xFF1E2229),
          child: ListTile(
            title: Text('#${o['id']} • ${o['service_title']} (${o['city']}) — ${o['address']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Набрано: $hired из $need чел. • Сумма: ${o['total_sum']} ₽ • Тел: ${o['client_phone']} • Статус: ${o['status']}'),
            trailing: Wrap(
              spacing: 6,
              children: [
                if (!full)
                  OutlinedButton(
                    onPressed: () => _addOneWorkerToOrder(o),
                    child: const Text('+1 чел.'),
                  ),
                IconButton(
                  tooltip: 'Скопировать текст заявки для СМС/WhatsApp',
                  icon: const Icon(Icons.copy, color: Colors.amber),
                  onPressed: () {
                    final txt = 'Заявка №${o['id']} • ${o['city']}, ${o['address']} • ${o['service_title']} (${o['needed_workers']} чел.) • К оплате: ${o['total_sum']} ₽';
                    Clipboard.setData(ClipboardData(text: txt));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Текст заявки скопирован в буфер обмена')));
                  },
                ),
                IconButton(
                  tooltip: 'Печать маршрутного листа (ХИНО С 738 СВ 125)',
                  icon: const Icon(Icons.print, color: Colors.lightBlueAccent),
                  onPressed: () => _openWaybillPrintWindow(o),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPricesTable() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _services.length,
      itemBuilder: (_, i) {
        final s = _services[i];
        final p = (s['parent_title'] ?? '').toString();
        return Card(
          color: const Color(0xFF1E2229),
          child: ListTile(
            title: Text(p.isEmpty ? '${s['title']}' : '$p → ${s['title']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Мин. заказ: ${s['min_hours']} ч • Макс. бригада: ${s['max_qty']} чел.'),
            trailing: Text('${s['rate']} ₽/час', style: const TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        );
      },
    );
  }

  Widget _buildBlacklistView() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _blacklist.length,
      itemBuilder: (_, i) {
        final b = _blacklist[i];
        return Card(
          color: const Color(0xFF1E2229),
          child: ListTile(
            leading: const Icon(Icons.block, color: Colors.redAccent),
            title: Text('${b['phone']}'),
            subtitle: Text('${b['reason']}'),
          ),
        );
      },
    );
  }
}
