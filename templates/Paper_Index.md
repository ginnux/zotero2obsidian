# 📚 论文管理中心

## 全部论文

```dataview
TABLE
  title as "标题",
  authors[0] as "一作",
  year as "年份",
  join(tags, ", ") as "标签",
  rating as "评分",
  date_added as "添加日期"
FROM "papers/notes"
SORT date_added DESC
```

## 🏷️ 按主题

### Reinforcement Learning
```dataview
TABLE title as "标题", year as "年份"
FROM "papers/notes"
WHERE contains(tags, "reinforcement-learning")
SORT year DESC
```

### LLM Alignment
```dataview
TABLE title as "标题", year as "年份"
FROM "papers/notes"
WHERE contains(tags, "LLM-alignment")
SORT year DESC
```

### Reasoning
```dataview
TABLE title as "标题", year as "年份"
FROM "papers/notes"
WHERE contains(tags, "reasoning") OR contains(tags, "math-reasoning") OR contains(tags, "code-reasoning")
SORT year DESC
```

## 📊 统计

- 总论文数：`$= dv.pages('"papers/notes"').length`

## 🔍 按一作查找

```dataview
TABLE title as "标题", year as "年份", join(tags, ", ") as "标签"
FROM "papers/notes"
SORT authors[0] ASC
```
