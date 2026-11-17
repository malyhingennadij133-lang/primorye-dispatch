import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

const String supabaseUrl = 'https://supabase.co';
const String supabaseKey = 'sb_publishable_9Y3IES6sn7s1onvGikCaNg_hsISZNc1';

void main() => runApp(const PrimoryeDispatcherWindows());

class PrimoryeDispatcherWindows extends StatelessWidget {
  const PrimoryeDispatcherWindows({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Приморье • Диспетчерская Windows',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0F172A),
        scaffoldBackgroundColor: const Color(0xFFE2E8F0),
      ),
      home: const DispatcherDesktopScreen(),
    );
  }
}

class DispatcherDesktopScreen extends StatefulWidget {
  const DispatcherDesktopScreen({super.key});

  @override
  State<DispatcherDesktopScreen> createState() =>
      _DispatcherDesktopScreenState();
}

class _DispatcherDesktopScreenState extends State<DispatcherDesktopScreen> {
  bool _loading = true;
  String _status = 'Подключение к облаку...';
  String _selectedCity = 'Артём';
  String _selectedServiceId = 'loaders';
  String _selectedCampus = 'Городской адрес (без кампуса)';
  String _selectedGate = 'Обычный подъезд (без ворот)';
  int _workersNeeded = 2;
  int _hoursCount = 2;

  final _addressCtrl = TextEditingController(text: 'ул. Кирова, 12');
  final _phoneCtrl = TextEditingController(text: '+7 914 ');
  List<Map<String, dynamic>> _orders = [];

  final List<String> _cities = [
    'Артём',
    'Уссурийск',
    'Владивосток',
    'Находка',
    'Большой Камень',
    'Спасск-Дальний',
  ];

  final List<Map<String, dynamic>> _services = [
    {'id': 'loaders', 'title': 'Грузчики', 'rate': 600},
    {'id': 'cargo', 'title': 'Грузовое такси', 'rate': 750},
    {'id': 'machinery', 'title': 'Спецтехника', 'rate': 2500},
    {'id': 'cleaning', 'title': 'Клининг и уборка', 'rate': 1800},
    {'id': 'taxi', 'title': 'Своё Такси (+ Отогрев)', 'rate': 150},
    {'id': 'rent', 'title': 'Аренда квартир и домов', 'rate': 1500},
    {'id': 'car_rent', 'title': 'Прокат авто', 'rate': 2500},
    {'id': 'electric', 'title': 'Электрик', 'rate': 500},
    {'id': 'courier', 'title': 'Курьер и Доставка', 'rate': 200},
  ];
  final List<String> _campuses = [
    'Городской адрес (без кампуса)',
    'Кампус ДВФУ (о. Русский) • Корпус A / B',
    'Кампус ДВФУ (о. Русский) • Корпус C / D',
    'Кампус ДВФУ (о. Русский) • Корпус E / F / G',
    'Кампус ДВФУ • Жилые корпуса (Север / Юг)',
    'Складской комплекс / РЦ (Угловое)',
    'Логистический терминал / Промзона',
  ];

  final List<String> _gates = [
    'Обычный подъезд (без ворот)',
    'Ворота №1',
    'Ворота №2',
    'Ворота №3',
    'Ворота №4',
    'Ворота №5',
    'Ворота №6',
    'Ворота №7',
    'Ворота №8',
    'Ворота №9',
    'Ворота №10',
    'Ворота №11–15 / Пандус КПП',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final res = await html.HttpRequest.request(
        '$supabaseUrl/rest/v1/orders?select=*',
        requestHeaders: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
        },
      );
      setState(() {
        _orders = res.status == 200
            ? (jsonDecode(res.responseText!) as List)
                  .cast<Map<String, dynamic>>()
            : [];
        _status = 'Диспетчерская онлайн • Заявок в работе: ${_orders.length}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Автономный режим (проверьте права в SQL Editor)';
        _loading = false;
      });
    }
  }

  Future<void> _createOrderByPhone() async {
    final srv = _services.firstWhere((s) => s['id'] == _selectedServiceId);
    final int total = (srv['rate'] as int) * _workersNeeded * _hoursCount;
    final String fullAddress =
        '${_addressCtrl.text} • $_selectedCampus • $_selectedGate • Тел: ${_phoneCtrl.text}';

    await html.HttpRequest.request(
      '$supabaseUrl/rest/v1/orders',
      method: 'POST',
      requestHeaders: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      sendData: jsonEncode({
        'service_id': srv['id'],
        'city': _selectedCity,
        'address_from': fullAddress,
        'description': '${srv['title']} (Оператор)',
        'workers_needed': _workersNeeded,
        'hours_count': _hoursCount,
        'total_price': total,
        'payment_method': 'Наличные / По звонку',
        'status': 'searching',
      }),
    );
    await _loadOrders();
  }

  Future<void> _setOrderStatus(String id, String newStatus) async {
    await html.HttpRequest.request(
      '$supabaseUrl/rest/v1/orders?id=eq.$id',
      method: 'PATCH',
      requestHeaders: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
      },
      sendData: jsonEncode({'status': newStatus}),
    );
    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    final srv = _services.firstWhere((s) => s['id'] == _selectedServiceId);
    final int previewTotal =
        (srv['rate'] as int) * _workersNeeded * _hoursCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.headset_mic, color: Color(0xFFFFC107)),
            const SizedBox(width: 12),
            const Text(
              'Приморье • Диспетчерская (Приём заявок по телефону)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 12, color: Colors.amberAccent),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить список заказов',
            onPressed: _loadOrders,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 380,
            color: Colors.white,
            padding: const EdgeInsets.all(18),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📞 Новый заказ по звонку',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'Город Приморья',
                      border: OutlineInputBorder(),
                    ),
                    items: _cities
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCity = v!),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedServiceId,
                    decoration: const InputDecoration(
                      labelText: 'Услуга',
                      border: OutlineInputBorder(),
                    ),
                    items: _services
                        .map(
                          (s) => DropdownMenuItem(
                            value: s['id'].toString(),
                            child: Text(s['title'].toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedServiceId = v!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Телефон клиента',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Улица и дом / Склад',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedCampus,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Кампус / Терминал',
                      border: OutlineInputBorder(),
                    ),
                    items: _campuses
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCampus = v!),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedGate,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Номер ворот / Пандус',
                      border: OutlineInputBorder(),
                    ),
                    items: _gates
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedGate = v!),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _workersNeeded,
                          decoration: const InputDecoration(
                            labelText: 'Чел / Машин',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(30, (i) => i + 1)
                              .map(
                                (n) => DropdownMenuItem(
                                  value: n,
                                  child: Text('$n'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _workersNeeded = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _hoursCount,
                          decoration: const InputDecoration(
                            labelText: 'Часов',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(12, (i) => i + 1)
                              .map(
                                (h) => DropdownMenuItem(
                                  value: h,
                                  child: Text('$h ч.'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _hoursCount = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _createOrderByPhone,
                      child: Text(
                        'ОФОРМИТЬ ЗАКАЗ ($previewTotal ₽)',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                ? const Center(
                    child: Text(
                      'Активных заказов нет. Оформите заявку слева по звонку клиента!',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _orders.length,
                    itemBuilder: (ctx, i) {
                      final o = _orders[i];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFC107),
                            child: Icon(
                              Icons.phone_in_talk,
                              color: Colors.black,
                            ),
                          ),
                          title: Text(
                            '${o['description']} — ${o['total_price']} ₽  [${o['status']}]',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '📍 г. ${o['city']}, ${o['address_from']}  •  Исполнителей: ${o['workers_assigned'] ?? 0} из ${o['workers_needed']}',
                          ),
                          trailing: o['status'] != 'cancelled'
                              ? OutlinedButton(
                                  onPressed: () => _setOrderStatus(
                                    o['id'].toString(),
                                    'cancelled',
                                  ),
                                  child: const Text(
                                    'Отменить',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                )
                              : const Text(
                                  'Отменён',
                                  style: TextStyle(color: Colors.grey),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
