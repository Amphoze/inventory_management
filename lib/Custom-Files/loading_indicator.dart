import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';

//warehouse loading animation
class WarehouseLoadingAnimation extends StatefulWidget {
  const WarehouseLoadingAnimation({Key? key}) : super(key: key);

  @override
  _WarehouseLoadingAnimationState createState() =>
      _WarehouseLoadingAnimationState();
}

class _WarehouseLoadingAnimationState extends State<WarehouseLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: AppColors.primaryGreen,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.warehouse_outlined,
            size: 100.0,
            color: _colorAnimation.value,
          ),
        );
      },
    );
  }
}

//prodcut loading animation
class ProductLoadingAnimation extends StatefulWidget {
  const ProductLoadingAnimation({Key? key}) : super(key: key);

  @override
  _ProductLoadingAnimationState createState() =>
      _ProductLoadingAnimationState();
}

class _ProductLoadingAnimationState extends State<ProductLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: AppColors.primaryBlue,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.production_quantity_limits_rounded,
            size: 100.0,
            color: _colorAnimation.value,
          ),
        );
      },
    );
  }
}

//categoyr loading animation
class CategoryLoadingAnimation extends StatefulWidget {
  const CategoryLoadingAnimation({Key? key}) : super(key: key);

  @override
  _CategoryLoadingAnimationState createState() =>
      _CategoryLoadingAnimationState();
}

class _CategoryLoadingAnimationState extends State<CategoryLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: AppColors.primaryBlue,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.category,
            size: 80.0,
            color: _colorAnimation.value,
          ),
        );
      },
    );
  }
}

//inventory loading animation
class InventoryLoadingAnimation extends StatefulWidget {
  const InventoryLoadingAnimation({Key? key}) : super(key: key);

  @override
  _InventoryLoadingAnimationState createState() =>
      _InventoryLoadingAnimationState();
}

class _InventoryLoadingAnimationState extends State<InventoryLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: AppColors.primaryGreen,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.inventory_2,
            size: 80.0,
            color: _colorAnimation.value,
          ),
        );
      },
    );
  }
}

//orders page loading animation
class OrdersLoadingAnimation extends StatefulWidget {
  const OrdersLoadingAnimation({Key? key}) : super(key: key);

  @override
  _OrdersLoadingAnimatioState createState() => _OrdersLoadingAnimatioState();
}

class _OrdersLoadingAnimatioState extends State<OrdersLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: AppColors.primaryGreen,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.shopping_cart,
            size: 80.0,
            color: _colorAnimation.value,
          ),
        );
      },
    );
  }
}

//orders page loading animation
class BookLoadingAnimation extends StatefulWidget {
  const BookLoadingAnimation({Key? key}) : super(key: key);

  @override
  _BookLoadingAnimatioState createState() => _BookLoadingAnimatioState();
}

class _BookLoadingAnimatioState extends State<BookLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: AppColors.primaryBlue,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.book_online,
            size: 80.0,
            color: _colorAnimation.value,
          ),
        );
      },
    );
  }
}

//orders page loading animation
class PickerLoadingAnimation extends StatefulWidget {
  const PickerLoadingAnimation({Key? key}) : super(key: key);

  @override
  _PickerLoadingAnimatioState createState() => _PickerLoadingAnimatioState();
}

class _PickerLoadingAnimatioState extends State<PickerLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: AppColors.primaryBlue,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.local_shipping,
            size: 80.0,
            color: _colorAnimation.value,
          ),
        );
      },
    );
  }
}

//packer page loading animation
class PackerLoadingAnimation extends StatefulWidget {
  const PackerLoadingAnimation({Key? key}) : super(key: key);

  @override
  _PackerLoadingAnimatioState createState() => _PackerLoadingAnimatioState();
}

class _PackerLoadingAnimatioState extends State<PackerLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: AppColors.primaryBlue,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.backpack_rounded,
            size: 80.0,
            color: _colorAnimation.value,
          ),
        );
      },
    );
  }
}

//checker page loading animation
class CheckerLoadingAnimation extends StatefulWidget {
  const CheckerLoadingAnimation({Key? key}) : super(key: key);

  @override
  _CheckerLoadingAnimatioState createState() => _CheckerLoadingAnimatioState();
}

class _CheckerLoadingAnimatioState extends State<CheckerLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: AppColors.primaryBlue,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.check_circle,
            size: 80.0,
            color: _colorAnimation.value,
          ),
        );
      },
    );
  }
}

//racked page loading animation
class RackedLoadingAnimation extends StatefulWidget {
  const RackedLoadingAnimation({Key? key}) : super(key: key);

  @override
  _RackedLoadingAnimatioState createState() => _RackedLoadingAnimatioState();
}

class _RackedLoadingAnimatioState extends State<RackedLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: AppColors.primaryBlue,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.shelves,
            size: 80.0,
            color: _colorAnimation.value,
          ),
        );
      },
    );
  }
}

//manifest page loading animation
class ManifestLoadingAnimation extends StatefulWidget {
  const ManifestLoadingAnimation({Key? key}) : super(key: key);

  @override
  _ManifestLoadingAnimatioState createState() =>
      _ManifestLoadingAnimatioState();
}

class _ManifestLoadingAnimatioState extends State<ManifestLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: AppColors.primaryBlue,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.star_border_outlined,
            size: 80.0,
            color: _colorAnimation.value,
          ),
        );
      },
    );
  }
}
