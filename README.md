# 🛒 Olist dbt Project

Bu proje, Brezilya'nın en büyük e-ticaret platformu 
Olist'in ham verisini dbt kullanarak temizleyip 
analiz için hazır hale getirmektedir.

---

## 🛠️ Kullanılan Teknolojiler

- **dbt Core 1.11.8** → SQL modellerini organize eder, test eder ve belgeler
- **Google BigQuery** → Veritabanı ve sorgu motoru
- **Google Cloud SDK** → BigQuery OAuth bağlantısı
- **GitHub** → Versiyon kontrolü ve portfolyo

---

## 📁 Proje Yapısı

```
olist_dbt/
├── models/
│   ├── staging/     → Ham veriyi temizleme katmanı
│   │   ├── schema.yml
│   │   ├── stg_orders.sql
│   │   ├── stg_payments.sql
│   │   ├── stg_reviews.sql
│   │   ├── stg_products.sql
│   │   └── stg_order_items.sql
│   └── marts/       → İş analizleri katmanı
│       ├── schema.yml
│       ├── mart_gelir.sql
│       ├── mart_memnuniyet.sql
│       └── mart_teslimat.sql
```

---


## 🔄 Veri Akışı

```
Ham BigQuery Tabloları (Olist dataset)
        ↓
Staging Modelleri (temizleme)
        ↓
Mart Modelleri (iş analizleri)
```

## 📦 Staging Modelleri

Ham veriyi temizleyip analiz için hazırlayan katman.
Tüm staging modelleri BigQuery'de **VIEW** olarak oluşturulur.

### stg_orders
Ham `olist_orders_dataset` tablosundan:
- Sadece `order_status = 'delivered'` olan siparişler alındı
- İptal edilen, işlemdeki veya teslim edilemeyen siparişler filtrelendi
- Gereksiz sütunlar atılarak sadece analiz için gerekli 8 sütun bırakıldı:
  `order_id, customer_id, order_status, order_purchase_timestamp,
   order_approved_at, order_delivered_carrier_date,
   order_delivered_customer_date, order_estimated_delivery_date`

### stg_payments
Ham `olist_order_payments_dataset` tablosundan:
- `payment_sequential` sütunu atıldı (bir siparişte birden fazla
  ödeme varsa sıra numarasıdır, analizde kullanılmaz)
- Gereksiz sütunlar temizlenerek sadece 4 sütun bırakıldı:
  `order_id, payment_type, payment_installments, payment_value`

### stg_reviews
Ham `olist_order_reviews_dataset` tablosundan:
- `SELECT DISTINCT` kullanılarak 814 duplicate review temizlendi
- Aynı review_id'nin 3 farklı siparişe bağlandığı sistematik
  bir veri hatası tespit edildi ve giderildi
- Yorum metni sütunları (`review_comment_title`,
  `review_comment_message`) atıldı, analizde kullanılmıyor
- Gereksiz sütunlar temizlenerek sadece 4 sütun bırakıldı:
  `review_id, order_id, review_score, review_creation_date`

### stg_products
Ham `olist_products_dataset` tablosundan:
- `product_category_name IS NOT NULL` filtresi eklendi
- Kategori adı olmayan ürünler mart_memnuniyet modelinde
  NULL değer üreteceğinden filtrelendi
- Ürün boyutları, ağırlık, fotoğraf sayısı gibi sütunlar
  atıldı, analizde kullanılmıyor
- Gereksiz sütunlar temizlenerek sadece 2 sütun bırakıldı:
  `product_id, product_category_name`

### stg_order_items
Ham `olist_order_items_dataset` tablosundan:
- Her sipariş içindeki ürün detaylarını içerir
- Bir siparişte birden fazla ürün olabilir (1'e Çok ilişki)
- `shipping_limit_date` sütunu atıldı, analizde kullanılmıyor
- Bu model staging katmanında kritik bir köprü görevi görür:
  reviews → order_items → products zinciri sayesinde
  yorumlar ile ürün kategorileri birleştirilebilir
- Gereksiz sütunlar temizlenerek sadece 6 sütun bırakıldı:
  `order_id, order_item_id, product_id, seller_id, price, freight_value`

---

## 📊 Mart Modelleri

İş sorularını cevaplayan katman.
Tüm mart modelleri BigQuery'de **TABLE** olarak oluşturulur
(hızlı erişim için fiziksel olarak saklanır).

### mart_gelir
**Soru:** "Olist ne kadar kazanıyor? Trendler nasıl?"
- `stg_orders` + `stg_payments` JOIN edildi
- Yıl, ay ve ödeme tipine göre gruplandı
- Her kombinasyon için sipariş adedi, toplam gelir
  ve ortalama sipariş değeri hesaplandı
- **Sonuç:** 85 satır (yıl × ay × ödeme tipi kombinasyonları)

### mart_memnuniyet
**Soru:** "Hangi kategoriler düşük puan alıyor?"
- `stg_reviews` + `stg_order_items` + `stg_products` JOIN edildi
- order_items köprü tablo görevi gördü (reviews → products)
- Kategori bazında ortalama puan hesaplandı
- 100'den az yorumu olan kategoriler `HAVING` ile filtrelendi
- En düşük puandan en yükseğe sıralandı
- **Sonuç:** 52 satır (100+ yorumu olan kategoriler)

### mart_teslimat
**Soru:** "Teslimatlar zamanında mı? Gecikme puanı etkiliyor mu?"
- `stg_orders` kullanıldı (zaten delivered filtrelenmiş)
- `DATE_DIFF` ile gerçek ve tahmini teslimat süreleri hesaplandı
- `CASE WHEN` ile her sipariş için gecikmeli mi değil mi
  (true/false) belirlendi
- **Sonuç:** 96,478 satır (teslim edilen tüm siparişler)

---

## ✅ Testler

25 data test yazıldı, **25/25 pass** ✅

| Test Tipi | Açıklama |
|-----------|----------|
| `unique` | PK sütunlarında tekrar yok |
| `not_null` | Kritik sütunlarda NULL yok |
| `accepted_values` | review_score 1-5 arası, late_delivery true/false |

---

## 🔑 Temel Bulgular

- **Toplam gelir:** 16M R$ (2016-2018)
- **2016→2017:** 150x büyüme
- **Ortalama puan:** 4.0/5
- **En düşük kategori:** office_furniture (3.49)
- **Gecikme oranı:** %8.11
- **Gecikme etkisi:** Puan 4.29'dan 2.57'ye düşüyor (%40)

---

## 🔗 İlgili Proje

SQL analiz projesi:
[olist_ecommerce_analysis](https://github.com/qcodepilot/olist_ecommerce_analysis)