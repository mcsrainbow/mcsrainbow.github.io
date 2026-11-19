resize `featured-image.jpeg`

```bash
sips --resampleWidth 2200 featured-image.jpeg --out featured-image.jpeg
imageoptim featured-image.jpeg
```

convert `featured-image.png` to jpeg and resize

```bash
sips -s format jpeg --resampleWidth 2200 featured-image.png --out featured-image.jpeg
imageoptim featured-image.jpeg
sed -i 's|featured-image.png|featured-image.jpeg|g' *.md
rm featured-image.png
```

convert `featured-image.webp` to jpeg and resize

```bash
sips -s format jpeg --resampleWidth 2200 featured-image.webp --out featured-image.jpeg
imageoptim featured-image.jpeg
sed -i 's|featured-image.webp|featured-image.jpeg|g' *.md
rm featured-image.webp
```

rename `featured-image.jpg` to jpeg and resize

```bash
mv featured-image.jpg featured-image.jpeg
sips --resampleWidth 2200 featured-image.jpeg --out featured-image.jpeg
sed -i 's|featured-image.jpg|featured-image.jpeg|g' *.md
imageoptim featured-image.jpeg
```
