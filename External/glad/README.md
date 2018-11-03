# How to generate glad

```shell
cd External/src/glad

python3 main.py --generator=c --spec gl --out-path=../../External/glad
python3 main.py --generator=c --spec wgl --out-path=../../External/glad
python3 main.py --generator=c --spec glx --out-path=../../External/glad
```