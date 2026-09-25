enum WarrantyStatus {
  active('Aktif'),
  expiringSoon('Hampir Habis'),
  expired('Kedaluwarsa');

  final String label;
  const WarrantyStatus(this.label);
}
