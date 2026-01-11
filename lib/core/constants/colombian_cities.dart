/// Lista de ciudades y municipios de Colombia organizados por departamentos
class ColombianCities {
  /// Map de departamentos con sus ciudades/municipios
  static const Map<String, List<String>> departments = {
    // Amazonas
    'Amazonas': ['Leticia'],
    
    // Antioquia
    'Antioquia': [
      'Medellín',
      'Bello',
      'Itagüí',
      'Envigado',
      'Sabaneta',
      'La Estrella',
      'Caldas',
      'Copacabana',
      'Girardota',
      'Barbosa',
      'Guarne',
      'Guatapé',
      'Marinilla',
      'Rionegro',
      'Turbo',
      'Apartadó',
      'Carepa',
      'Chigorodó',
      'Necoclí',
    ],
    
    // Arauca
    'Arauca': ['Arauca'],
    
    // Atlántico
    'Atlántico': [
      'Barranquilla',
      'Soledad',
      'Malambo',
      'Sabanalarga',
      'Puerto Colombia',
      'Galapa',
      'Usiacurí',
    ],
    
    // Bolívar
    'Bolívar': [
      'Cartagena',
      'Magangué',
      'Turbaco',
      'Arjona',
      'Mahates',
      'San Pablo',
    ],
    
    // Boyacá
    'Boyacá': [
      'Tunja',
      'Duitama',
      'Sogamoso',
      'Chiquinquirá',
      'Villa de Leyva',
      'Paipa',
      'Ráquira',
    ],
    
    // Caldas
    'Caldas': [
      'Manizales',
      'Pensilvania',
      'Chinchiná',
      'Villamaría',
      'Palestina',
    ],
    
    // Caquetá
    'Caquetá': ['Florencia'],
    
    // Casanare
    'Casanare': ['Yopal'],
    
    // Cauca
    'Cauca': [
      'Popayán',
      'Silvia',
      'Puracé',
    ],
    
    // Cesar
    'Cesar': [
      'Valledupar',
      'Aguachica',
      'Codazzi',
    ],
    
    // Chocó
    'Chocó': [
      'Quibdó',
      'Nuquí',
    ],
    
    // Córdoba
    'Córdoba': [
      'Montería',
      'Cereté',
      'Sahagún',
      'Ciénaga de Oro',
      'Lorica',
    ],
    
    // Cundinamarca
    'Cundinamarca': [
      'Bogotá',
      'Soacha',
      'Chía',
      'Zipaquirá',
      'Facatativá',
      'Girardot',
      'Fusagasugá',
      'Mosquera',
      'Madrid',
      'Cajicá',
      'La Calera',
      'Tabio',
      'Tenjo',
      'Sibaté',
      'Sopó',
      'Tocancipá',
      'Gachancipá',
      'Cogua',
      'Nemocón',
      'Guatavita',
      'Guasca',
      'La Vega',
      'El Rosal',
      'Subachoque',
      'Bojacá',
      'San Antonio del Tequendama',
    ],
    
    // Guainía
    'Guainía': ['Inírida'],
    
    // Guaviare
    'Guaviare': ['San José del Guaviare'],
    
    // Huila
    'Huila': [
      'Neiva',
      'Pitalito',
      'Garzón',
      'La Plata',
    ],
    
    // La Guajira
    'La Guajira': [
      'Riohacha',
      'Maicao',
      'Uribia',
    ],
    
    // Magdalena
    'Magdalena': [
      'Santa Marta',
      'Ciénaga',
      'Fundación',
      'Aracataca',
    ],
    
    // Meta
    'Meta': [
      'Villavicencio',
      'Acacías',
      'Granada',
      'San Martín',
      'Restrepo',
    ],
    
    // Nariño
    'Nariño': [
      'Pasto',
      'Ipiales',
      'Tumaco',
    ],
    
    // Norte de Santander
    'Norte de Santander': [
      'Cúcuta',
      'Villa del Rosario',
      'Los Patios',
      'Ocaña',
      'Pamplona',
    ],
    
    // Putumayo
    'Putumayo': ['Mocoa'],
    
    // Quindío
    'Quindío': [
      'Armenia',
      'Calarcá',
      'La Tebaida',
      'Circasia',
      'Quimbaya',
    ],
    
    // Risaralda
    'Risaralda': [
      'Pereira',
      'Dosquebradas',
      'Santa Rosa de Cabal',
      'Cartago',
      'La Virginia',
    ],
    
    // San Andrés y Providencia
    'San Andrés y Providencia': [
      'San Andrés',
      'Providencia',
    ],
    
    // Santander
    'Santander': [
      'Bucaramanga',
      'Floridablanca',
      'Girón',
      'Piedecuesta',
      'Barrancabermeja',
      'San Gil',
      'Barbosa',
    ],
    
    // Sucre
    'Sucre': [
      'Sincelejo',
      'Corozal',
      'Morroa',
    ],
    
    // Tolima
    'Tolima': [
      'Ibagué',
      'Espinal',
      'Girardot',
      'Melgar',
      'Chaparral',
    ],
    
    // Valle del Cauca
    'Valle del Cauca': [
      'Cali',
      'Palmira',
      'Buenaventura',
      'Tuluá',
      'Buga',
      'Cartago',
      'Jamundí',
      'Yumbo',
      'Ginebra',
      'Guacarí',
      'El Cerrito',
      'Restrepo',
      'Candelaria',
    ],
    
    // Vaupés
    'Vaupés': ['Mitú'],
    
    // Vichada
    'Vichada': ['Puerto Carreño'],
  };

  /// Obtener lista de departamentos ordenados alfabéticamente
  static List<String> get departmentsList {
    final deptList = departments.keys.toList();
    deptList.sort();
    return deptList;
  }

  /// Obtener ciudades de un departamento ordenadas alfabéticamente
  static List<String> getCitiesForDepartment(String department) {
    final cities = departments[department];
    if (cities == null) return [];
    final sortedCities = List<String>.from(cities);
    sortedCities.sort();
    return sortedCities;
  }

  /// Obtener todas las ciudades (para compatibilidad con código anterior)
  @Deprecated('Use departments instead')
  static List<String> get cities {
    final allCities = <String>[];
    for (final citiesList in departments.values) {
      allCities.addAll(citiesList);
    }
    return allCities;
  }

  /// Obtener ciudades ordenadas alfabéticamente (para compatibilidad)
  @Deprecated('Use getCitiesForDepartment instead')
  static List<String> get sortedCities {
    final sorted = cities;
    sorted.sort();
    return sorted;
  }
}
