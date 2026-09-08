extends RefCounted

var checks: int = 0
var failures: int = 0


func expect_true(value: bool, message: String) -> void:
	checks += 1
	if not value:
		_fail(message, "expected true")


func expect_false(value: bool, message: String) -> void:
	checks += 1
	if value:
		_fail(message, "expected false")


func expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	checks += 1
	if actual != expected:
		_fail(message, "expected %s, got %s" % [str(expected), str(actual)])


func expect_float(actual: float, expected: float, tolerance: float, message: String) -> void:
	checks += 1
	if absf(actual - expected) > tolerance:
		_fail(message, "expected %.6f ± %.6f, got %.6f" % [expected, tolerance, actual])


func expect_not_null(value: Variant, message: String) -> void:
	checks += 1
	if value == null:
		_fail(message, "expected a non-null value")


func _fail(message: String, detail: String) -> void:
	failures += 1
	push_error("FAIL: %s — %s" % [message, detail])


func print_summary() -> void:
	if failures == 0:
		print("TEST PASS: %d checks" % checks)
	else:
		print("TEST FAIL: %d of %d checks failed" % [failures, checks])
