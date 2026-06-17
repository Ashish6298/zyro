function errorHandler(err, req, res, next) {
  console.error("Unhandled Error:", err);
  res.status(err.status || 500).json({
    success: false,
    error: err.message || "Internal Server Error",
  });
}

module.exports = errorHandler;
