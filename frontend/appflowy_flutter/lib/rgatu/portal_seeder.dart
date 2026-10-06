import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/rgatu/portal_config.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';

/// Seeds the private ZVS-26 RGATU workspace once.
///
/// This application is intentionally single-group. There is no group picker,
/// multi-tenant university portal or schedule module here.
class RgatuPortalSeeder {
  const RgatuPortalSeeder._();

  static const String _marker = '🎓 ЗВС-26 · РГАТУ';

  static const List<String> _subjects = [
    'Экономика',
    'Культурология',
    'Математический анализ',
    'Физическая культура',
    'История России',
    'Линейная алгебра и геометрия',
    'Теоретические основы информатики и ИКТ',
    'Иностранный язык',
    'Дискретная математика',
    'Основы программирования',
  ];

  static const List<String> _teachers = [
    'Авдеева В.В.',
    'Бурцев А.И.',
    'Гайдуков Э.А.',
    'Гусарова Н.И.',
    'Каленов А.С.',
    'Сидорова И.М.',
    'Сизов П.В.',
    'Ферагина Е.А.',
    'Фоменко С.А.',
    'Чижикова Н.В.',
  ];

  static Future<void> ensureSeeded(String workspaceId) async {
    if (workspaceId.isEmpty) return;

    final allViewsResult = await ViewBackendService.getAllViews();
    final alreadySeeded = allViewsResult.fold(
      (views) => views.items.any((view) => view.name == _marker),
      (error) {
        Log.error('ZVS-26 portal seeder: failed to read views: ${error.msg}');
        return true;
      },
    );

    if (alreadySeeded) return;

    await _createDocument(
      parentId: workspaceId,
      name: _marker,
      markdown: _homeMarkdown,
    );

    await _createDocument(
      parentId: workspaceId,
      name: '📢 Важное',
      markdown: _importantMarkdown,
    );

    final semester = await _createDocument(
      parentId: workspaceId,
      name: '1️⃣ 1 семестр',
      markdown: _semesterMarkdown,
    );

    if (semester != null) {
      for (final subject in _subjects) {
        final subjectPage = await _createDocument(
          parentId: semester.id,
          name: subject,
          markdown: _subjectMarkdown(subject),
        );

        if (subjectPage != null) {
          await _createDocument(
            parentId: subjectPage.id,
            name: '📌 Что сдаём',
            markdown: _requirementsMarkdown,
          );
          await _createDocument(
            parentId: subjectPage.id,
            name: '📝 ДКР и задания',
            markdown: _assignmentsMarkdown,
          );
          await _createDocument(
            parentId: subjectPage.id,
            name: '📚 Конспекты',
            markdown: _notesMarkdown,
          );
          await _createDocument(
            parentId: subjectPage.id,
            name: '📎 Материалы',
            markdown: _subjectMaterialsMarkdown,
          );
          await _createDocument(
            parentId: subjectPage.id,
            name: '💬 Важное от преподавателя',
            markdown: _teacherNotesMarkdown,
          );
        }
      }
    }

    await _createDocument(
      parentId: workspaceId,
      name: '📝 ДКР и задания',
      markdown: _allAssignmentsMarkdown,
    );

    final sessions = await _createDocument(
      parentId: workspaceId,
      name: '🎓 Сессии',
      markdown: _sessionsMarkdown,
    );
    if (sessions != null) {
      await _createDocument(
        parentId: sessions.id,
        name: 'Установочная сессия',
        markdown: _sessionPageMarkdown('Установочная сессия'),
      );
      await _createDocument(
        parentId: sessions.id,
        name: 'Экзаменационная сессия',
        markdown: _sessionPageMarkdown('Экзаменационная сессия'),
      );
      await _createDocument(
        parentId: sessions.id,
        name: 'Зачёты и экзамены',
        markdown: _examsMarkdown,
      );
    }

    final teachers = await _createDocument(
      parentId: workspaceId,
      name: '👨‍🏫 Преподаватели',
      markdown: _teachersIndexMarkdown,
    );
    if (teachers != null) {
      for (final teacher in _teachers) {
        await _createDocument(
          parentId: teachers.id,
          name: teacher,
          markdown: _teacherMarkdown(teacher),
        );
      }
    }

    final materials = await _createDocument(
      parentId: workspaceId,
      name: '📚 Материалы',
      markdown: _materialsIndexMarkdown,
    );
    if (materials != null) {
      await _createDocument(
        parentId: materials.id,
        name: 'Методички',
        markdown: _fileShelfMarkdown('Методички'),
      );
      await _createDocument(
        parentId: materials.id,
        name: 'Лекции и конспекты',
        markdown: _fileShelfMarkdown('Лекции и конспекты'),
      );
      await _createDocument(
        parentId: materials.id,
        name: 'Примеры работ',
        markdown: _fileShelfMarkdown('Примеры работ'),
      );
      await _createDocument(
        parentId: materials.id,
        name: 'Разное',
        markdown: _fileShelfMarkdown('Разное'),
      );
    }

    final university = await _createDocument(
      parentId: workspaceId,
      name: '🏫 РГАТУ',
      markdown: _rgatuMarkdown,
    );
    if (university != null) {
      await _createDocument(
        parentId: university.id,
        name: 'ЛК1',
        markdown: _externalServiceMarkdown(
          title: 'ЛК1',
          url: RgatuPortalConfig.lk1Url,
          note: 'Старый личный кабинет ФЗО.',
        ),
      );
      await _createDocument(
        parentId: university.id,
        name: 'ЛК2',
        markdown: _externalServiceMarkdown(
          title: 'ЛК2',
          url: RgatuPortalConfig.lk2Url,
          note: 'Новый личный кабинет РГАТУ.',
        ),
      );
      await _createDocument(
        parentId: university.id,
        name: 'ФЗО',
        markdown: _externalServiceMarkdown(
          title: 'ФЗО',
          url: RgatuPortalConfig.fzoUrl,
          note: 'Официальный раздел факультета заочного обучения.',
        ),
      );
      await _createDocument(
        parentId: university.id,
        name: 'Корпуса и аудитории',
        markdown: _campusMarkdown,
      );
      await _createDocument(
        parentId: university.id,
        name: 'Полезные ссылки',
        markdown: _linksMarkdown,
      );
    }

    final group = await _createDocument(
      parentId: workspaceId,
      name: '👥 Наша группа',
      markdown: _groupMarkdown,
    );
    if (group != null) {
      await _createDocument(
        parentId: group.id,
        name: 'Участники',
        markdown: _membersMarkdown,
      );
      await _createDocument(
        parentId: group.id,
        name: 'Объявления',
        markdown: _announcementsMarkdown,
      );
      await _createDocument(
        parentId: group.id,
        name: 'Договорённости',
        markdown: _agreementsMarkdown,
      );
    }

    final templates = await _createDocument(
      parentId: workspaceId,
      name: '🧩 Шаблоны',
      markdown: _templatesMarkdown,
    );
    if (templates != null) {
      await _createDocument(
        parentId: templates.id,
        name: 'Карточка предмета',
        markdown: _subjectTemplateMarkdown,
      );
      await _createDocument(
        parentId: templates.id,
        name: 'Новая ДКР',
        markdown: _dkrTemplateMarkdown,
      );
      await _createDocument(
        parentId: templates.id,
        name: 'Конспект',
        markdown: _noteTemplateMarkdown,
      );
      await _createDocument(
        parentId: templates.id,
        name: 'Карточка преподавателя',
        markdown: _teacherTemplateMarkdown,
      );
      await _createDocument(
        parentId: templates.id,
        name: 'Объявление группы',
        markdown: _announcementTemplateMarkdown,
      );
    }

    final archive = await _createDocument(
      parentId: workspaceId,
      name: '🗃 Архив',
      markdown: _archiveMarkdown,
    );
    if (archive != null) {
      await _createDocument(
        parentId: archive.id,
        name: 'Семестры',
        markdown: _archiveShelfMarkdown('Семестры'),
      );
      await _createDocument(
        parentId: archive.id,
        name: 'Старые ДКР',
        markdown: _archiveShelfMarkdown('Старые ДКР'),
      );
      await _createDocument(
        parentId: archive.id,
        name: 'Старые материалы',
        markdown: _archiveShelfMarkdown('Старые материалы'),
      );
    }

    Log.info(
      'Private ${RgatuPortalConfig.group} RGATU portal seeded for workspace '
      '$workspaceId',
    );
  }

  static Future<ViewPB?> _createDocument({
    required String parentId,
    required String name,
    String? markdown,
  }) async {
    List<int>? initialDataBytes;

    if (markdown != null && markdown.trim().isNotEmpty) {
      final document = customMarkdownToDocument(markdown);
      initialDataBytes =
          DocumentDataPBFromTo.fromDocument(document)?.writeToBuffer();
    }

    final result = await ViewBackendService.createView(
      layoutType: ViewLayoutPB.Document,
      parentViewId: parentId,
      name: name,
      initialDataBytes: initialDataBytes,
    );

    return result.fold(
      (view) => view,
      (error) {
        Log.error('ZVS-26 portal seeder: failed to create "$name": ${error.msg}');
        return null;
      },
    );
  }

  static const String _homeMarkdown = '''
# ЗВС-26 · РГАТУ

> Закрытый неофициальный портал нашей группы. Здесь хранится то, что не должно потеряться в чате.

## Быстро

- **1 семестр** — предметы и вся информация по ним.
- **ДКР и задания** — общий список того, что нужно сделать и сдать.
- **Сессии** — подготовка к установочной и экзаменационной сессиям.
- **Преподаватели** — требования, контакты и договорённости.
- **Материалы** — методички, лекции, примеры работ и файлы.
- **РГАТУ** — ЛК1, ЛК2, ФЗО, корпуса и официальные ссылки.
- **Наша группа** — объявления и общие договорённости.

## Главное правило

Если информация нужна не только сегодня — фиксируем её здесь, а не оставляем единственным сообщением в чате.

**Расписания в этом портале нет.** Для него используется отдельное приложение.
''';

  static const String _importantMarkdown = '''
# Важное

Используем эту страницу только для информации, которую должны увидеть все пять человек.

## Сейчас

- [ ] Добавить актуальное объявление
- [ ] Проверить ближайшие дедлайны
- [ ] Зафиксировать изменения по ДКР / сессии

## Правило

Старое важное не удаляем бесследно: после потери актуальности переносим в подходящий раздел или архив.
''';

  static const String _semesterMarkdown = '''
# 1 семестр

Все знания храним **по предметам**, а не кучей файлов.

Внутри каждого предмета уже есть:

- что сдаём;
- ДКР и задания;
- конспекты;
- материалы;
- важное от преподавателя.
''';

  static String _subjectMarkdown(String subject) => '''
# $subject

## Коротко

**Преподаватель:** заполнить  
**Форма аттестации:** заполнить  
**Что сдаём:** открыть вложенную страницу «📌 Что сдаём»

## Здесь должно быть

- основные требования по предмету;
- полезные ссылки;
- важные договорённости;
- итоговая информация, которую неудобно искать в переписке.

> Не складываем всё на одну страницу: подробные материалы находятся во вложенных разделах.
''';

  static const String _requirementsMarkdown = '''
# Что сдаём

## Итог по предмету

- **Форма аттестации:** заполнить
- **Условия допуска:** заполнить
- **Что обязательно сдать:** заполнить

## ДКР / контрольные

- [ ] Задание или работа
- [ ] Проверено
- [ ] Принято

## Лабораторные / практические

- [ ] Добавить требования

## Дедлайны

| Что | Срок | Статус |
| --- | --- | --- |
| Добавить работу | — | Не начато |

## Что сказал преподаватель

Фиксируем здесь требования, которые были озвучены устно или в переписке.
''';

  static const String _assignmentsMarkdown = '''
# ДКР и задания

Для каждой крупной работы создаём отдельную вложенную страницу или копируем шаблон «Новая ДКР».

## Активные

- [ ] Добавить первую работу

## Готово

Переносим сюда после сдачи, но не удаляем — пригодится группе и для архива.
''';

  static const String _notesMarkdown = '''
# Конспекты

Одна тема или занятие — один понятный блок.

## Как называть

**Дата · тема**

Пример: **06.10 · Введение и основные понятия**

## Содержание

Добавляйте текст, формулы, изображения, файлы и ссылки прямо в документ.
''';

  static const String _subjectMaterialsMarkdown = '''
# Материалы

Сюда кладём только материалы этого предмета:

- методички;
- презентации;
- задания;
- примеры;
- полезные ссылки;
- файлы преподавателя.

Название должно быть понятно без контекста чата.
''';

  static const String _teacherNotesMarkdown = '''
# Важное от преподавателя

## Требования

Заполнить.

## Как сдавать

Заполнить.

## Что важно не забыть

- [ ] Добавить первую договорённость

> Если преподаватель изменил требования — обновляем эту страницу, а старую формулировку при необходимости оставляем ниже с датой.
''';

  static const String _allAssignmentsMarkdown = '''
# Все ДКР и задания

Это обзорная страница. Подробности каждой работы хранятся внутри соответствующего предмета.

## Нужно сделать

- [ ] Добавить ближайшую работу

## На проверке

Пока пусто.

## Принято

Пока пусто.
''';

  static const String _sessionsMarkdown = '''
# Сессии

Здесь не расписание занятий, а **подготовка и результаты**:

- что нужно сдать до сессии;
- документы и материалы;
- зачёты и экзамены;
- организационные договорённости;
- итоговые результаты.
''';

  static String _sessionPageMarkdown(String title) => '''
# $title

## До начала

- [ ] Проверить, что нужно сдать заранее
- [ ] Собрать материалы
- [ ] Зафиксировать важные даты

## Во время

Добавляем только то, что относится к организации и подготовке.

## После

Фиксируем результаты и переносим завершённые материалы в архив.
''';

  static const String _examsMarkdown = '''
# Зачёты и экзамены

| Предмет | Формат | Что нужно | Результат |
| --- | --- | --- | --- |
| Добавить предмет | — | — | — |

Для подробностей используем страницу самого предмета.
''';

  static const String _teachersIndexMarkdown = '''
# Преподаватели

У каждого преподавателя отдельная карточка.

Храним:

- связанные предметы;
- контакты, если они были даны группе;
- требования;
- формат сдачи;
- важные договорённости.
''';

  static String _teacherMarkdown(String teacher) => '''
# $teacher

**Предмет(ы):** заполнить  
**Контакты:** заполнить только если преподаватель дал их группе

## Как сдавать

Заполнить.

## Требования

Заполнить.

## Важные договорённости

- Добавить информацию с датой, если требования меняются.
''';

  static const String _materialsIndexMarkdown = '''
# Материалы

Общая полка файлов, которые относятся сразу к группе или нескольким предметам.

Предметные файлы лучше хранить внутри страницы соответствующего предмета.
''';

  static String _fileShelfMarkdown(String title) => '''
# $title

Добавляйте файлы и ссылки с понятными названиями.

Не используем названия вроде **file1.pdf**, если можно написать, что внутри.
''';

  static String get _rgatuMarkdown => '''
# РГАТУ

Быстрые официальные ресурсы университета.

- [Сайт РГАТУ](${RgatuPortalConfig.universityUrl})
- [ФЗО](${RgatuPortalConfig.fzoUrl})
- [ЛК1](${RgatuPortalConfig.lk1Url})
- [ЛК2](${RgatuPortalConfig.lk2Url})

> Портал ЗВС-26 не является официальным сервисом РГАТУ.
''';

  static String _externalServiceMarkdown({
    required String title,
    required String url,
    required String note,
  }) => '''
# $title

$note

**Открыть:** [$url]($url)

Не сохраняем здесь пароли, коды доступа и другие секреты.
''';

  static const String _campusMarkdown = '''
# Корпуса и аудитории

## Как читать аудиторию

- **3-321** → корпус 3, этаж 3, аудитория 321.
- **Г-105** → главный корпус, этаж 1, аудитория 105.

Добавляйте сюда только полезную справочную информацию: входы, этажи, особенности поиска кабинета и официальные адреса.
''';

  static String get _linksMarkdown => '''
# Полезные ссылки

- [РГАТУ](${RgatuPortalConfig.universityUrl})
- [ФЗО](${RgatuPortalConfig.fzoUrl})
- [ЛК1](${RgatuPortalConfig.lk1Url})
- [ЛК2](${RgatuPortalConfig.lk2Url})

Добавляйте сюда только ссылки, полезные всей группе.
''';

  static const String _groupMarkdown = '''
# Наша группа · ЗВС-26

Внутреннее пространство пяти одногруппников.

Здесь не нужны формальности: только информация, которую удобно иметь под рукой всем.
''';

  static const String _membersMarkdown = '''
# Участники

Нас пять. Заполняем только то, что участник сам хочет хранить в общей базе.

1. —
2. —
3. —
4. —
5. —

Можно добавить удобный способ связи. Личные или чувствительные данные сюда не складываем.
''';

  static const String _announcementsMarkdown = '''
# Объявления группы

## Актуальные

- Добавить объявление

## Архив объявлений

После потери актуальности переносим сюда, если информация ещё может пригодиться.
''';

  static const String _agreementsMarkdown = '''
# Договорённости

Фиксируем решения, чтобы потом не искать «а что мы там решили в чате».

## Учёба

- Добавить договорённость

## Организация

- Добавить договорённость

## Кто что делает

- [ ] Добавить задачу и ответственного
''';

  static const String _templatesMarkdown = '''
# Шаблоны

Копируем нужную страницу и заполняем вместо того, чтобы каждый раз придумывать структуру заново.
''';

  static const String _subjectTemplateMarkdown = '''
# Название предмета

**Преподаватель:**  
**Форма аттестации:**  

## Что сдаём

- [ ] 

## Важное

## Полезные ссылки

## Материалы
''';

  static const String _dkrTemplateMarkdown = '''
# ДКР · название

**Предмет:**  
**Статус:** Не начато  
**Срок:**  
**Тема / вариант:**  

## Требования

## План

- [ ] Разобраться с заданием
- [ ] Подготовить работу
- [ ] Проверить оформление
- [ ] Отправить / сдать
- [ ] Получить подтверждение

## Файлы

## Комментарии преподавателя

## Результат
''';

  static const String _noteTemplateMarkdown = '''
# Дата · тема

**Предмет:**  
**Источник:** занятие / методичка / другое

## Ключевые мысли

## Подробно

## Что непонятно

- [ ] 

## Связанные материалы
''';

  static const String _teacherTemplateMarkdown = '''
# ФИО преподавателя

**Предмет(ы):**  
**Контакты:**  

## Требования

## Как сдавать

## Важные договорённости

## История изменений

- Дата — что изменилось
''';

  static const String _announcementTemplateMarkdown = '''
# Короткий заголовок

**Дата:**  
**Актуально до:**  
**Кому:** всей группе

## Что произошло

## Что нужно сделать

- [ ] 

## Ссылки / файлы
''';

  static const String _archiveMarkdown = '''
# Архив

Ничего полезного не удаляем только потому, что закончился семестр.

Переносим завершённые разделы сюда, чтобы текущая база оставалась чистой, а старые знания можно было найти через несколько лет.
''';

  static String _archiveShelfMarkdown(String title) => '''
# $title

Сюда переносим завершённые материалы. Названия должны сохранять семестр / год / предмет, чтобы поиск работал через несколько лет.
''';
}
