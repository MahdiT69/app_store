import 'package:app_store/utils/api_provider.dart';

class ProductController {
  final ApiProvider _apiProvider = ApiProvider();

  Future<Map<String, dynamic>> fetchProducts({
    String search = "",
    String category = "all",
    int page = 1,
    int pageSize = 6,
    String sort = "recent",
  }) {
    return _apiProvider.getProducts(
      search: search,
      category: category,
      page: page,
      pageSize: pageSize,
      sort: sort,
    );
  }

  Future<List<String>> fetchCategories() {
    return _apiProvider.getCategories();
  }
}