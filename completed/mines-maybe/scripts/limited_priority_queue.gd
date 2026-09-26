class_name LimitedPriorityQueue
## Data structure implementing a rudimentary Priority Queue with an inherent maximum size
##
## New elements are added with a basic [method add] function.
## The collection of values can be recovered (as a copy) with a simple [method get_array] function.

## Defines the values currently in the queue.
## Default structure supports [type float], but this may be expanded in the future.
var _values: Array[float] = []
## Defines the maximum length of the array.
## Default structure supports five elements, but this may allow expanded functionality in the future.
var max_size: int = 5

## Method for adding elements to the array. If the class is adjusted, I'll do some template work here.
func add(value: float) -> void:
	_values.append(value)
	_values.sort()
	if _values.size() > max_size:
		_values.resize(max_size)

## Getter method for fetching the array. Technically, the array can be fetched naturally,
## but the [member _values] are private, so this getter makes it available.
func get_array() -> Array:
	return _values.duplicate()
