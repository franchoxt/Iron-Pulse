// Enums definidos en .agents/rules/tablas-supabase.md

/// Rol del usuario (admin vs cliente)
enum UserRole {
  client,
  admin;

  static UserRole fromString(String? value) {
    if (value == 'admin') return UserRole.admin;
    return UserRole.client;
  }

  String toDbString() => name;
}

/// Estado de reserva
enum BookingStatus {
  confirmed,
  waitlist,
  cancelled;

  static BookingStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'waitlist':
        return BookingStatus.waitlist;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'confirmed':
      default:
        return BookingStatus.confirmed;
    }
  }

  String toDbString() => name;

  String get displayName {
    switch (this) {
      case BookingStatus.confirmed:
        return 'Confirmada';
      case BookingStatus.waitlist:
        return 'Lista de espera';
      case BookingStatus.cancelled:
        return 'Cancelada';
    }
  }
}

/// Intensidad de la clase
enum ClassIntensity {
  low,
  medium,
  high;

  static ClassIntensity fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return ClassIntensity.low;
      case 'high':
        return ClassIntensity.high;
      case 'medium':
      default:
        return ClassIntensity.medium;
    }
  }

  String toDbString() {
    switch (this) {
      case ClassIntensity.low:
        return 'Low';
      case ClassIntensity.medium:
        return 'Medium';
      case ClassIntensity.high:
        return 'High';
    }
  }

  String get displayName {
    switch (this) {
      case ClassIntensity.low:
        return 'Low';
      case ClassIntensity.medium:
        return 'Medium';
      case ClassIntensity.high:
        return 'High';
    }
  }
}
