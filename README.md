# Msgpack


## Usage

### Pack
```gdscript
result = Msgpack.pack(data)
```
 - `data` - Variant
 - `result` - PackedByteArray

### Unpack
```gdscript
result = Msgpack.unpack(data)
```
 - `data` - PackedByteArray
 - `result` - Variant

### Example
```gdscript
class MsgpackDataSerializer:
    func serialize(data: Dictionary):
        return Msgpack.pack(data)

    func deserialize(data: PackedByteArray):
        return Msgpack.unpack(data)
```


## Contributing


Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request.
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/new_feature`)
3. Commit your Changes (`git commit -m 'Add some new_feature'`)
4. Push to the Branch (`git push origin feature/new_feature`)
5. Open a Pull Request

## License


Distributed under the MIT License. See [LICENSE](LICENSE.md) for more information.


## Contact

Marko Švetak
- Email: masvetak@gmail.com
- Facebook: facebook.com/masvetak


