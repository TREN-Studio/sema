# SEMA Format — Developer Deployment Prompt
## TREN Studio | trenstudio.com/sema

---

## المشكلة التي تم حلها
ملف `install_sema_windows.bat` كان يظهر:
- أيقونة gear عادية بدون هوية
- تحذير "Unknown Publisher" من Windows
- مظهر غير احترافي يخيف المستخدمين

---

## الحل المقدم — 3 خيارات مرتبة من الأفضل للأبسط

---

### ✅ الخيار 1 — PowerShell GUI (الأفضل الآن — مجاني)

**الملفات:**
- `Install-SEMA.ps1` — المثبّت بواجهة رسومية احترافية
- `Install SEMA Format.bat` — مشغّل خفي يفتح PowerShell بدون نافذة cmd

**للمستخدم:**
1. يضغط بالزر الأيمن على `Install SEMA Format.bat`
2. يختار **"Run as administrator"**
3. تظهر نافذة GUI احترافية بألوان TREN Studio
4. يضغط "Install SEMA Format"
5. تظهر رسالة نجاح

**الفرق عن .bat:**
- بدل نافذة CMD سوداء مخيفة → نافذة GUI بألوان تركوازية
- تحذير Windows لا يزال يظهر (مرة واحدة فقط) لكن يبدو أفضل كثيراً
- يمكن ترفعه على الموقع مباشرة

---

### 🏆 الخيار 2 — Inno Setup Installer (الأحترف — مجاني)

**الأداة المطلوبة:**
تنزيل Inno Setup: https://jrsoftware.org/isdl.php

**خطوات البناء:**
1. تثبيت Inno Setup
2. فتح `sema_setup.iss`
3. تعديل هذا السطر: `Source: "files\sema_launcher.exe"` 
   → استبداله بـ: `Source: "files\sema-viewer.html"`
4. حذف هذا السطر: `SetupIconFile=sema_icon.ico` (حتى تحصل على أيقونة)
5. Compile → ينتج `SEMA-Setup-v1.0.0.exe`

**النتيجة:**
- مثبّت `.exe` بواجهة Windows installer كاملة (مثل أي برنامج)
- يظهر اسم TREN Studio في نافذة التثبيت
- يضيف قائمة في Start Menu
- يضيف Uninstall في Control Panel

---

### 💡 الخيار 3 — Code Signing Certificate (الاحترافي الكامل)

لإزالة تحذير "Unknown Publisher" نهائياً:

| المزود | النوع | السعر / سنة |
|--------|-------|-------------|
| Sectigo | OV Code Signing | ~$90 |
| DigiCert | OV Code Signing | ~$150 |
| SSL.com | EV Code Signing | ~$250 |

**بعد الحصول على الشهادة:**
```powershell
# توقيع الملف
signtool sign /a /n "TREN Studio" /t http://timestamp.digicert.com "SEMA-Setup.exe"
```

**النتيجة:** تحذير SmartScreen يختفي تماماً، ويظهر اسم TREN Studio باللون الأزرق بدلاً من "Unknown Publisher".

---

## هيكل الملفات للرفع

```
trenstudio.com/sema/
├── index.html
├── sema-spec.html
├── sema-viewer.html
├── .htaccess
├── files/
│   ├── Install-SEMA.ps1           ← PowerShell installer
│   ├── Install SEMA Format.bat   ← المشغّل (يستدعي PS1)
│   ├── SEMA-Setup-v1.0.0.exe     ← Inno Setup installer (بعد البناء)
│   ├── sema_builder.py
│   ├── install_sema_macos.sh
│   ├── install_sema_linux.sh
│   └── harira_recipe.sema
```

---

## تحديث روابط التنزيل في index.html

```html
<!-- Windows — الرئيسي -->
<a href="files/SEMA-Setup-v1.0.0.exe" download>
  Download for Windows (.exe)
</a>

<!-- Windows — البديل -->
<a href="files/Install-SEMA.ps1" download>
  PowerShell Installer
</a>

<!-- macOS -->
<a href="files/install_sema_macos.sh" download>
  Download for macOS
</a>

<!-- Linux -->
<a href="files/install_sema_linux.sh" download>
  Download for Linux
</a>
```

---

## ملاحظة مهمة

حتى مع Inno Setup، Windows SmartScreen قد يحذر المستخدمين الجدد
(لأن الملف جديد وغير معروف بعد). هذا يختفي تلقائياً بعد أن يحمّله
عدد كافٍ من المستخدمين — أو فوراً مع Code Signing Certificate.

**التوصية:** ابدأ بـ PowerShell GUI الآن، وعندما يكبر المشروع
اشترِ Code Signing Certificate لإزالة التحذير نهائياً.

---

*TREN Studio — Building the future of files.*
*https://trenstudio.com/sema*
