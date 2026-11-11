import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:test_app/models/order.dart';
import 'package:test_app/models/product.dart';
import 'package:test_app/providers/auth_provider.dart';
import 'package:test_app/providers/cart_provider.dart';
import 'package:test_app/providers/order_provider.dart';
import 'package:test_app/providers/product_provider.dart';
import 'package:test_app/screens/cart_screen.dart';
import 'package:test_app/screens/home_screen.dart';
import 'package:test_app/screens/login_screen.dart';
import 'package:test_app/services/product_service.dart';

void main() {
  group('E-Commerce App Unit & Widget Tests', () {
    test('Product model calculates discount percentage properly', () {
      const product = Product(
        id: 'test_1',
        name: 'Test Product',
        description: 'Test Description',
        price: 80.0,
        originalPrice: 100.0,
        rating: 4.5,
        reviewCount: 10,
        category: 'Electronics',
        imageUrl: 'https://example.com/test.jpg',
      );

      expect(product.discountPercentage, 20);
    });

    test('CartProvider calculates subtotal, taxes, shipping and items correctly', () {
      final cart = CartProvider();
      const product = Product(
        id: 'p1',
        name: 'Headphones',
        description: 'Noise cancelling',
        price: 50.0,
        originalPrice: 60.0,
        rating: 4.8,
        reviewCount: 100,
        category: 'Electronics',
        imageUrl: 'https://example.com/p1.jpg',
      );

      expect(cart.isEmpty, true);
      expect(cart.totalItemCount, 0);

      // Add 1 item
      cart.addItem(product);
      expect(cart.totalItemCount, 1);
      expect(cart.subtotal, 50.0);
      expect(cart.shippingFee, 9.99); // Under $75 threshold
      expect(cart.estimatedTax, 2.50); // 5% of 50
      expect(cart.totalAmount, closeTo(62.49, 0.01));

      // Add another quantity
      cart.addItem(product, quantity: 1);
      expect(cart.totalItemCount, 2);
      expect(cart.subtotal, 100.0);
      expect(cart.shippingFee, 0.0); // Over $75 is free
      expect(cart.estimatedTax, 5.00); // 5% of 100
      expect(cart.totalAmount, closeTo(105.00, 0.01));

      // Decrease quantity
      cart.removeSingleItem('p1');
      expect(cart.totalItemCount, 1);

      // Remove product
      cart.removeItem('p1');
      expect(cart.isEmpty, true);
    });

    test('ProductService returns products across all specified categories', () {
      final all = ProductService.getAllProducts();
      expect(all.isNotEmpty, true);

      final electronics = ProductService.getProductsByCategory('Electronics');
      expect(electronics.isNotEmpty, true);

      final fashion = ProductService.getProductsByCategory('Fashion');
      expect(fashion.isNotEmpty, true);

      final shoes = ProductService.getProductsByCategory('Shoes');
      expect(shoes.isNotEmpty, true);

      final home = ProductService.getProductsByCategory('Home Appliances');
      expect(home.isNotEmpty, true);
    });

    test('OrderModel parses JSON and calculates values correctly', () {
      final json = {
        '_id': 'ord_test_123',
        'items': [
          {
            'productId': 'p1',
            'name': 'Sony WH-1000XM5',
            'price': 399.99,
            'quantity': 2,
            'imageUrl': 'https://example.com/p1.jpg',
          }
        ],
        'deliveryAddress': {
          'fullName': 'John Doe',
          'phone': '1234567890',
          'street': '123 Tech Way',
          'city': 'San Jose',
          'postalCode': '95134',
        },
        'subtotal': 799.98,
        'shippingFee': 0.0,
        'tax': 40.0,
        'totalAmount': 839.98,
        'paymentMethod': 'Credit Card',
        'status': 'Processing',
        'createdAt': '2026-11-03T12:00:00.000Z',
      };

      final order = OrderModel.fromJson(json);
      expect(order.id, 'ord_test_123');
      expect(order.items.length, 1);
      expect(order.items.first.name, 'Sony WH-1000XM5');
      expect(order.totalAmount, 839.98);
      expect(order.status, 'Processing');
      expect(order.deliveryAddress.fullName, 'John Doe');
    });

    testWidgets('LoginScreen displays form fields and sign-in button', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => ProductProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Welcome to ShopEase'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('CartScreen displays empty cart state when no products added', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => ProductProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Your Cart is Empty'), findsOneWidget);
      expect(find.text('Explore Products'), findsOneWidget);
    });

    testWidgets('HomeScreen loads search bar and promotional banner without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => ProductProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('ShopEase'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Featured Products'), findsOneWidget);
      expect(find.text('Popular Products'), findsOneWidget);
    });
  });
}
