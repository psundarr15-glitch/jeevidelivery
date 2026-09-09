/// Support contact details from GET /pages/support (admin-configurable —
/// see Admin > Help & Support Settings on the backend). The exact field
/// names aren't something this app controls, so every field is read
/// defensively from a couple of plausible key spellings and everything
/// is nullable — the screen just shows whichever of these came back.
class SupportInfo {
  final String? phone;
  final String? email;
  final String? whatsapp;
  final String? message;

  SupportInfo({this.phone, this.email, this.whatsapp, this.message});

  static String? _pick(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    return null;
  }

  factory SupportInfo.fromJson(Map<String, dynamic> j) => SupportInfo(
        phone: _pick(j, ['phone', 'support_phone', 'contact_phone']),
        email: _pick(j, ['email', 'support_email', 'contact_email']),
        whatsapp: _pick(j, ['whatsapp', 'whatsapp_number', 'whatsapp_phone']),
        message: _pick(j, ['message', 'note', 'description']),
      );

  bool get hasAnyContact => phone != null || email != null || whatsapp != null;
}

/// Shape used by the "About" style static-content pages: a title plus a
/// list of paragraph/heading sections.
class StaticContentSection {
  final String? heading;
  final String body;
  StaticContentSection({this.heading, required this.body});

  factory StaticContentSection.fromJson(Map<String, dynamic> j) => StaticContentSection(
        heading: j['heading']?.toString(),
        body: j['body']?.toString() ?? '',
      );
}

class StaticContentPage {
  final String title;
  final String? updated;
  final List<StaticContentSection> sections;
  StaticContentPage({required this.title, this.updated, required this.sections});

  factory StaticContentPage.fromJson(Map<String, dynamic> j) => StaticContentPage(
        title: j['title']?.toString() ?? '',
        updated: j['updated']?.toString(),
        sections: (j['sections'] as List? ?? []).map((e) => StaticContentSection.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
