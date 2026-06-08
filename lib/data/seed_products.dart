class SeedProducts {
  const SeedProducts._();

  static const List<Map<String, dynamic>> products = [
    {
      'name': 'Real Madrid Home Jersey',
      'price': 1500,
      'category': 'jersey',
      'imagePath': 'product_images/jerseys/RM.jpg',
      'quantity': 10,
      'sizes': {
        'S': {'price': 1500, 'stock': 10},
        'M': {'price': 1500, 'stock': 10},
        'L': {'price': 1500, 'stock': 10},
        'XL': {'price': 1500, 'stock': 10},
      },
    },
    {
      'name': 'Liverpool Home Jersey',
      'price': 1600,
      'category': 'jersey',
      'imagePath': 'product_images/jerseys/livjpg.jpg',
      'quantity': 8,
      'sizes': {
        'S': {'price': 1600, 'stock': 8},
        'M': {'price': 1600, 'stock': 8},
        'L': {'price': 1600, 'stock': 8},
        'XL': {'price': 1600, 'stock': 8},
      },
    },
    {
      'name': 'PSG Home Jersey',
      'price': 1700,
      'category': 'jersey',
      'imagePath': 'product_images/jerseys/psg.jpeg',
      'quantity': 7,
      'sizes': {
        'S': {'price': 1700, 'stock': 7},
        'M': {'price': 1700, 'stock': 7},
        'L': {'price': 1700, 'stock': 7},
        'XL': {'price': 1700, 'stock': 7},
      },
    },
    {
      'name': 'Adidas Crew Socks',
      'price': 350,
      'category': 'socks',
      'imagePath': 'product_images/socks/adidassocks.webp',
      'quantity': 24,
      'sizes': {
        'S': {'price': 350, 'stock': 24},
        'M': {'price': 350, 'stock': 24},
        'L': {'price': 350, 'stock': 24},
      },
    },
    {
      'name': 'Adidas Match Socks',
      'price': 420,
      'category': 'socks',
      'imagePath': 'product_images/socks/adidassocks1.webp',
      'quantity': 18,
      'sizes': {
        'S': {'price': 420, 'stock': 18},
        'M': {'price': 420, 'stock': 18},
        'L': {'price': 420, 'stock': 18},
      },
    },
    {
      'name': 'Nike Air Zoom Boots',
      'price': 2900,
      'category': 'trainers',
      'imagePath': 'product_images/boots/Nikeairzoom.webp',
      'quantity': 9,
      'sizes': {
        '40': {'price': 2900, 'stock': 9},
        '41': {'price': 2900, 'stock': 9},
        '42': {'price': 2900, 'stock': 9},
        '43': {'price': 2900, 'stock': 9},
        '44': {'price': 2900, 'stock': 9},
      },
    },
    {
      'name': 'Adidas Predator Boots',
      'price': 3100,
      'category': 'trainers',
      'imagePath': 'product_images/boots/adidaspredator.jpg',
      'quantity': 6,
      'sizes': {
        '40': {'price': 3100, 'stock': 6},
        '41': {'price': 3100, 'stock': 6},
        '42': {'price': 3100, 'stock': 6},
        '43': {'price': 3100, 'stock': 6},
        '44': {'price': 3100, 'stock': 6},
      },
    },
    {
      'name': 'Football Shin Guard',
      'price': 600,
      'category': 'accessories',
      'imagePath': 'product_images/accessories/shinguard.jpg',
      'quantity': 15,
      'sizes': {
        'One Size': {'price': 600, 'stock': 15},
      },
    },
  ];
}
