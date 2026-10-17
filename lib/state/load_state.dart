enum LoadState { initial, loading, success, error }

extension LoadStateX on LoadState {
  bool get isLoading => this == LoadState.loading;
  bool get isError => this == LoadState.error;
  bool get isSuccess => this == LoadState.success;
}
