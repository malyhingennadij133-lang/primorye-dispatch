import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

void main() => runApp(const PrimoryeDispatchApp());

const String kSupabaseUrl = 'https://supabase.co';
const String kSupabaseKey = 'sb_publishable_9Y3IES6sn7s1onvGlkCaNg_hsISZNc1';

class PrimoryeDispatchApp extends StatelessWidget {
  const PrimoryeDispatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Приморье • Диспетчерская (Windows)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFF59E0B),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      ),
      home: const DispatchScreen(),
    );
  }
}

class DispatchScreen extends StatefulWidget {
  const DispatchScreen({super.key});

  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  final _dispatchPhoneCtrl = TextEditingController(text: '+7 (914) ');
  final _clientPhoneCtrl = TextEditingController(text: '+7 914 ');
  final _addressCtrl = TextEditingController();

  String _boundDispatchPhone = 'Не привязан';
  String _selectedCity = 'Артём';
  String _selectedService = 'Грузчики';
  String _selectedCampus = 'Городской адрес (без кампуса)';
  String _selectedGate = 'Обычный подъезд (без ворот)';
  String _paymentType = 'Наличные';
  int _workersCount = 2;
  int _hoursCount = 2;

  Map<String, int> _rates = {
    'Грузчики': 700,
    'Разнорабочие': 650,
    'Тяжёлые работы': 900,
    'Универсалы': 750,
    'Грузовое такси': 1400,
    'Спецтехника': 2500,
    'Интернет-мастер': 1200,
  };

  List<Map<String, dynamic>> _activeOrders = [];
  int get _totalPrice => (_rates[_selectedService] ?? 700) * _workersCount * _hoursCount;

  Map<String, String> get _headers => {
        'apikey': kSupabaseKey,
        'Authorization': 'Bearer $kSupabaseKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  @override
  void initState() {
    super.initState();
    _syncFromCloud();
  }

  Future<void> _syncFromCloud() async {
    try {
      final srvReq = await html.HttpRequest.request(
        '$kSupabaseUrl/rest/v1/services?select=*&order=sort_order.asc',
        method: 'GET',
        requestHeaders: _headers,
      );
      if (srvReq.status == 200 && srvReq.responseText != null) {
        final List srvList = jsonDecode(srvReq.responseText!);
        if (srvList.isNotEmpty) {
          final Map<String, int> loadedRates = {};
          for (final item in list) {
            final t = '${item['title'] ?? ''}'.trim();
            final r = (item['rate'] as num?)?.toInt() ?? 700;
            if (t.isNotEmpty) loadedRates[t] = r;
          }
          if (loadedRates.isNotEmpty && mounted) {
            setState(() {
              _rates = loadedRates;
              if (!_rates.containsKey(_selectedService)) {
                _selectedService = _rates.keys.first;
              }
            });
          }
        }
      }

      final ordReq = await html.HttpRequest.request(
        '$kSupabaseUrl/rest/v1/orders?select=*&order=created_at.desc',
        method: 'GET',
        requestHeaders: _headers,
      );
      if (ordReq.status == 200 && ordReq.responseText != null) {
        final List ordList = jsonDecode(ordReq.responseText!);
        if (mounted) {
          setState(() => _activeOrders = ordList.cast<Map<String, dynamic>>());
        }
      }
    } catch (_) {}
  }
  int get _totalPrice => (_rates[_selectedService] ?? 700) * _workersCount * _hoursCount;

  Map<String, String> get _headers => {
        'apikey': kSupabaseKey,
        'Authorization': 'Bearer $kSupabaseKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  @override
  void initState() {
    super.initState();
    _syncFromCloud();
  }

  Future<void> _syncFromCloud() async {
    try {
      final srvReq = await html.HttpRequest.request(
        '$kSupabaseUrl/rest/v1/services?select=*&order=sort_order.asc',
        method: 'GET',
        requestHeaders: _headers,
      );
      if (srvReq.status == 200 && srvReq.responseText != null) {
        final List srvList = jsonDecode(srvReq.responseText!);
        if (srvList.isNotEmpty) {
          final Map<String, int> loadedRates = {};
          for (final item in srvList) {
            final t = '${item['title'] ?? ''}'.trim();
            final r = (item['rate'] as num?)?.toInt() ?? 700;
            if (t.isNotEmpty) loadedRates[t] = r;
          }
          if (loadedRates.isNotEmpty && mounted) {
            setState(() {
              _rates = loadedRates;
              if (!_rates.containsKey(_selectedService)) {
                _selectedService = _rates.keys.first;
              }
            });
          }
        }
      }

      final ordReq = await html.HttpRequest.request(
        '$kSupabaseUrl/rest/v1/orders?select=*&order=created_at.desc',
        method: 'GET',
        requestHeaders: _headers,
      );
      if (ordReq.status == 200 && ordReq.responseText != null) {
        final List ordList = jsonDecode(ordReq.responseText!);
        if (mounted) {
          setState(() => _activeOrders = ordList.cast<Map<String, dynamic>>());
        }
      }
    } catch (_) {}
  }
  @override
  Widget build(BuildContext context) {
    final cities = ['Артём', 'Владивосток', 'Уссурийск', 'Находка', 'Большой Камень', 'Спасск-Дальний', 'Арсеньев'];
    final campuses = [
      'Городской адрес (без кампуса)',
      'Кампус ДВФУ (о. Русский)',
      'Аэропорт Кневичи (Артём)',
      'Промзона / Логистический парк',
      'Морской порт / Терминал',
    ];
    final gates = [
      'Обычный подъезд (без ворот)',
      'Ворота №1 (Пандус)',
      'Ворота №2',
      'Ворота №3',
      'Ворота №4',
      'КПП / Въезд по пропуску',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        toolbarHeight: 68,
        title: Row(
          children: [
            const Icon(Icons.headset_mic_rounded, color: Color(0xFFF59E0B), size: 28),
            const SizedBox(width: 10),
            const Text('Приморье • Диспетчерская', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _boundDispatchPhone == 'Не привязан' ? Colors.red.withOpacity(0.25) : const Color(0xFF065F46),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '📞 Линия: $_boundDispatchPhone',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _boundDispatchPhone == 'Не привязан' ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 205,
              height: 40,
              child: TextField(
                controller: _dispatchPhoneCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '+7 (914) 000-00-00',
                  hintStyle: const TextStyle(color: Colors.white54),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
              onPressed: _bindPhoneNumber,
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text('Привязать номер'),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          Container(
            width: 420,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const Text('📞 Новый заказ по звонку', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(labelText: 'Город Приморья', border: OutlineInputBorder(), isDense: true),
                  items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCity = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedService,
                  decoration: const InputDecoration(labelText: 'Услуга (из базы)', border: OutlineInputBorder(), isDense: true),
                  items: _rates.keys.map((s) => DropdownMenuItem(value: s, child: Text('$s (${_rates[s]} ₽/ч)'))).toList(),
                  onChanged: (v) => setState(() => _selectedService = v!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _clientPhoneCtrl,
                        decoration: const InputDecoration(labelText: 'Телефон клиента', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                      onPressed: () => _callNumber(_clientPhoneCtrl.text),
                      icon: const Icon(Icons.call_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Улица и дом / Склад', hintText: 'ул. Кирова, 12', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCampus,
                  decoration: const InputDecoration(labelText: 'Кампус / Терминал', border: OutlineInputBorder(), isDense: true),
                  items: campuses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCampus = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedGate,
                  decoration: const InputDecoration(labelText: 'Номер ворот / Пандус', border: OutlineInputBorder(), isDense: true),
                  items: gates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _selectedGate = v!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _workersCount,
                        decoration: const InputDecoration(labelText: 'Чел / Машин (до 30)', border: OutlineInputBorder(), isDense: true),
                        items: List.generate(30, (i) => i + 1).map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                        onChanged: (v) => setState(() => _workersCount = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _hoursCount,
                        decoration: const InputDecoration(labelText: 'Часов', border: OutlineInputBorder(), isDense: true),
                        items: List.generate(12, (i) => i + 1).map((h) => DropdownMenuItem(value: h, child: Text('$h ч.'))).toList(),
                        onChanged: (v) => setState(() => _hoursCount = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _paymentType,
                  decoration: const InputDecoration(labelText: 'Способ оплаты', border: OutlineInputBorder(), isDense: true),
                  items: ['Наличные', 'Перевод на карту / СБП', 'Корпоративный (на счёт)'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => _paymentType = v!),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _createOrder,
                  child: Text('ОФОРМИТЬ ЗАКАЗ ($_totalPrice ₽)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ),
      body: Row(
        children: [
          Container(
            width: 420,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const Text('📞 Новый заказ по звонку', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(labelText: 'Город Приморья', border: OutlineInputBorder(), isDense: true),
                  items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCity = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedService,
                  decoration: const InputDecoration(labelText: 'Услуга (из базы)', border: OutlineInputBorder(), isDense: true),
                  items: _rates.keys.map((s) => DropdownMenuItem(value: s, child: Text('$s (${_rates[s]} ₽/ч)'))).toList(),
                  onChanged: (v) => setState(() => _selectedService = v!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _clientPhoneCtrl,
                        decoration: const InputDecoration(labelText: 'Телефон клиента', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                      onPressed: () => _callNumber(_clientPhoneCtrl.text),
                      icon: const Icon(Icons.call_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Улица и дом / Склад', hintText: 'ул. Кирова, 12', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCampus,
                  decoration: const InputDecoration(labelText: 'Кампус / Терминал', border: OutlineInputBorder(), isDense: true),
                  items: campuses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCampus = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedGate,
                  decoration: const InputDecoration(labelText: 'Номер ворот / Пандус', border: OutlineInputBorder(), isDense: true),
                  items: gates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _selectedGate = v!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _workersCount,
                        decoration: const InputDecoration(labelText: 'Чел / Машин (до 30)', border: OutlineInputBorder(), isDense: true),
                        items: List.generate(30, (i) => i + 1).map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                        onChanged: (v) => setState(() => _workersCount = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _hoursCount,
                        decoration: const InputDecoration(labelText: 'Часов', border: OutlineInputBorder(), isDense: true),
                        items: List.generate(12, (i) => i + 1).map((h) => DropdownMenuItem(value: h, child: Text('$h ч.'))).toList(),
                        onChanged: (v) => setState(() => _hoursCount = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _paymentType,
                  decoration: const InputDecoration(labelText: 'Способ оплаты', border: OutlineInputBorder(), isDense: true),
                  items: ['Наличные', 'Перевод на карту / СБП', 'Корпоративный (на счёт)'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => _paymentType = v!),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _createOrder,
                  child: Text('ОФОРМИТЬ ЗАКАЗ ($_totalPrice ₽)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Активные заявки из базы (${_activeOrders.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      OutlinedButton.icon(onPressed: _syncFromCloud, icon: const Icon(Icons.refresh_rounded), label: const Text('Обновить базу')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _activeOrders.isEmpty
                        ? const Center(
                            child: Text(
                              'Привяжите рабочий номер вверху справа и примите первый заказ по звонку',
                              style: TextStyle(color: Colors.black54, fontSize: 15),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _activeOrders.length,
                            itemBuilder: (context, i) {
                              final o = _activeOrders[i];
                              return Card(
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(backgroundColor: const Color(0xFF111827), child: Text('${i + 1}', style: const TextStyle(color: Colors.white))),
                                  title: Text('${o['service'] ?? 'Заказ'} — ${o['price'] ?? 0} ₽', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Город: ${o['city'] ?? ''} • ${o['address'] ?? ''}\nКлиент: ${o['client_phone'] ?? ''} • Статус: ${o['status'] ?? 'В работе'}'),
                                  isThreeLine: true,
                                  trailing: IconButton.filled(
                                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                                    tooltip: 'Перезвонить клиенту',
                                    onPressed: () => _callNumber('${o['client_phone'] ?? ''}'),
                                    icon: const Icon(Icons.phone_forwarded_rounded, color: Colors.white),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
