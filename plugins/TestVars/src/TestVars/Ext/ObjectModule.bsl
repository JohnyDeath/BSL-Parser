﻿
// Плагин для проверки использования переменных и параметров.
// Отслеживаются следующие ситуации:
// - значение переменной не читается после присваивания (объявление тоже считается присваиванием)
// - значение параметра-значения не читается после присваивания
// - к параметру-ссылке нет обращений
//
// примечания:
// Анализ в целом выполняется поверхностно и возможны ложные срабатывания.

// todo: проверять два присваивания одной переменной подряд

Перем Узлы;
Перем Результат;

Перем Переменные, Параметры;

Процедура Инициализировать(ПарсерBSL) Экспорт
	Узлы = ПарсерBSL.Узлы();
	Результат = Новый Массив;
	Переменные = Новый Соответствие;
	Параметры = Новый Соответствие;
КонецПроцедуры // Инициализировать() 

Функция Результат() Экспорт
	Возврат СтрСоединить(Результат, Символы.ПС);
КонецФункции // Результат()

Функция Интерфейс() Экспорт
	Перем Интерфейс;
	Интерфейс = Новый Массив;
	Интерфейс.Добавить("ПослеПосещенияИнструкцииПрисваивания");
	Интерфейс.Добавить("ПосетитьВыражениеИдентификатор");
	Интерфейс.Добавить("ПосетитьОбъявлениеМетода");
	Интерфейс.Добавить("ПослеПосещенияОбъявленияМетода");
	Возврат Интерфейс;
КонецФункции // Интерфейс() 

Процедура ПослеПосещенияИнструкцииПрисваивания(ИнструкцияПрисваивания, Стек, Счетчики) Экспорт
	Перем Имя, Объявление, Операция; 
	Если ИнструкцияПрисваивания.Левый.Аргументы <> Неопределено Или ИнструкцияПрисваивания.Левый.Хвост.Количество() > 0 Тогда
		Возврат;
	КонецЕсли;
	Имя = ИнструкцияПрисваивания.Левый.Голова.Имя; 
	Операция = Переменные[Имя];
	Если Операция <> Неопределено Тогда
		Если Операция = "GetInLoop" Тогда
			Переменные[Имя] = "Get";
		Иначе
			Переменные[Имя] = "Set";
		КонецЕсли;
		Возврат;
	КонецЕсли; 	
	Объявление = ИнструкцияПрисваивания.Левый.Голова.Объявление;
	Операция = Параметры[Объявление];	
	Если Операция <> Неопределено Тогда
		Если Операция = "GetInLoop" Тогда
			Параметры[Объявление] = "Get";
		Иначе
			Параметры[Объявление] = "Set";
		КонецЕсли; 
	КонецЕсли; 
КонецПроцедуры // ПослеПосещенияИнструкцииПрисваивания()

Процедура ПосетитьВыражениеИдентификатор(ВыражениеИдентификатор, Стек, Счетчики) Экспорт
	Перем Имя, Объявление, Операция;
	Если ВыражениеИдентификатор.Хвост.Количество() = 0
		And Стек.Родитель.Тип = Узлы.ИнструкцияПрисваивания
		And Стек.Родитель.Левый = ВыражениеИдентификатор Тогда
		Возврат;
	КонецЕсли;
	Если Счетчики.ИнструкцияПока + Счетчики.ИнструкцияДля + Счетчики.ИнструкцияДляКаждого > 0 Тогда
		Операция = "GetInLoop";
	Иначе
		Операция = "Get";
	КонецЕсли; 
	Имя = ВыражениеИдентификатор.Голова.Имя;
	Объявление = ВыражениеИдентификатор.Голова.Объявление;
	Если Переменные[Имя] <> Неопределено Тогда
		Переменные[Имя] = Операция;
	ИначеЕсли Параметры[Объявление] <> Неопределено Тогда
		Параметры[Объявление] = Операция;	
	КонецЕсли; 
КонецПроцедуры // ПосетитьВыражениеИдентификатор()

Процедура ПосетитьОбъявлениеМетода(ОбъявлениеМетода, Стек, Счетчики) Экспорт
	Переменные = Новый Соответствие;
	Параметры = Новый Соответствие;		
	Для Каждого Параметр Из ОбъявлениеМетода.Сигнатура.Параметры Цикл
		Параметры[Параметр] = "Get";
		//Параметры[Параметр] = "Nil"; <- чтобы чекать все параметры (в формах адъ)
	КонецЦикла;
	Для Каждого ОбъявлениеЛокальнойПеременной Из ОбъявлениеМетода.Переменные Цикл
		Переменные[ОбъявлениеЛокальнойПеременной.Имя] = "Set";
	КонецЦикла;
	Для Каждого Объект Из ОбъявлениеМетода.Авто Цикл
		Переменные[Объект.Имя] = "Set";
	КонецЦикла;
КонецПроцедуры // ПосетитьОбъявлениеМетода()

Процедура ПослеПосещенияОбъявленияМетода(ОбъявлениеМетода, Стек, Счетчики) Экспорт
	Перем Метод;
	Если ОбъявлениеМетода.Сигнатура.Тип = Узлы.СигнатураФункции Тогда
		Метод = "Функция";
	Иначе
		Метод = "Процедура";
	КонецЕсли; 
	Для Каждого Элемент Из Переменные Цикл
		Если Not СтрНачинаетсяС(Элемент.Значение, "Get") Тогда
			Результат.Добавить(СтрШаблон("%1 `%2()` содержит неиспользуемую переменную `%3`", Метод, ОбъявлениеМетода.Сигнатура.Имя, Элемент.Ключ));
		КонецЕсли; 
	КонецЦикла;
	Для Каждого Элемент Из Параметры Цикл
		Если Элемент.Значение = "Nil" Или Элемент.Значение = "Set" And Элемент.Ключ.ПоЗначению Тогда
			Результат.Добавить(СтрШаблон("%1 `%2()` содержит неиспользуемый параметр `%3`", Метод, ОбъявлениеМетода.Сигнатура.Имя, Элемент.Ключ.Имя));
		КонецЕсли; 
	КонецЦикла;
КонецПроцедуры // ПослеПосещенияОбъявленияМетода()