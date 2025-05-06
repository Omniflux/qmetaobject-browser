#include <windows.h>

#include <QObject>
#include <QMetaObject>
#include <QMetaProperty>
#include <QTreeWidget>
#include <QVBoxLayout>

#include <dzapp.h>
#include <dzclassfactory.h>
#include <dzstyledefs.h>

#include "qmetaobjectbrowser.hpp"

OfQMetaObjectBrowserPane::OfQMetaObjectBrowserPane() : DzPane("QMetaObject Browser")
{
	const auto margin = this->style()->pixelMetric(DZ_PM_GeneralMargin);

	auto layout = new QVBoxLayout();
	layout->setMargin(margin);
	layout->setSpacing(margin);

	this->m_QMetaObjectTree = new QTreeWidget();
	this->m_QMetaObjectTree->setHeaderLabel("Class");
	layout->addWidget(this->m_QMetaObjectTree);

	this->setLayout(layout);
}

void OfQMetaObjectBrowserPane::refresh()
{
	this->addClass(dzApp);

	auto classFactoryIterator = DzApp::classFactoryIterator();
	while (classFactoryIterator.hasNext())
	{
		this->addClass(classFactoryIterator.next()->metaObject());
	}

	this->m_QMetaObjectTree->clear();
	this->m_QMetaObjectTree->insertTopLevelItems(0, this->m_items);
	this->m_QMetaObjectTree->sortItems(0, Qt::AscendingOrder);
}

QObject* OfQMetaObjectBrowserPane::checkType(void* obj)
{
	auto qobject = static_cast<QObject*>(obj);

	__try
	{
		causeAccessViolationIfNotQObject(qobject);
	}
	__except (EXCEPTION_EXECUTE_HANDLER)
	{
		qobject = nullptr;
	}

	return qobject;
}

void OfQMetaObjectBrowserPane::causeAccessViolationIfNotQObject(const QObject* obj)
{
	QString().compare(obj->metaObject()->className());
}

void OfQMetaObjectBrowserPane::addClass(const QObject* const object)
{
	const auto metaObject = object->metaObject();
	this->addClass(metaObject);

	for (auto i = metaObject->methodOffset(), end = metaObject->methodCount(); i < end; ++i)
	{
		const auto method = metaObject->method(i);
		const auto signature = QString(method.signature());
		const auto returnType = QString(method.typeName()).replace('*', "");
		if (signature.startsWith("get") &&
			signature.endsWith("()") &&
			QString(method.typeName()).endsWith('*') &&
			!this->m_metaObjects.contains(returnType))
		{
			void* retVal;
			if (method.invoke(const_cast<QObject*>(object), Qt::DirectConnection, QGenericReturnArgument(method.typeName(), &retVal)))
			{
				if (const auto retObj = checkType(retVal))
				{
					this->addClass(retObj);
				}
				else
				{
					// Failed conversion to QObject, don't try again
					this->m_metaObjects.append(returnType);
				}
			}
		}
	}
}

void OfQMetaObjectBrowserPane::addClass(const QMetaObject* const metaObject)
{
	static char* rwTypeName[] = { "noaccess", "readonly", "writeonly", "readwrite"};
	static char* accessTypeName[] = { "private", "protected", "public"};
	static char* methodTypeName[] = { "method", "signal", "slot", "constructor" };

	if (!this->m_metaObjects.contains(metaObject->className()))
	{
		this->m_metaObjects.append(metaObject->className());

		auto classItem = new QTreeWidgetItem(QStringList(QString("%1").arg(metaObject->className())));

		// Info
		for (int i = metaObject->classInfoOffset(); i < metaObject->classInfoCount(); ++i)
		{
			const auto infoItem = new TreeWidgetItem(QStringList(QString("[info] %1: %2")
				.arg(metaObject->classInfo(i).name())
				.arg(metaObject->classInfo(i).value())
			));
			classItem->addChild(infoItem);
		}

		// Properties
		for (int i = metaObject->propertyOffset(); i < metaObject->propertyCount(); ++i)
		{
			const auto propertyItem = new TreeWidgetItem(QStringList(QString("%1 [property] %2 -> %3")
				.arg(rwTypeName[int(metaObject->property(i).isReadable()) | (metaObject->property(i).isWritable() << 1)])
				.arg(metaObject->property(i).name())
				.arg(metaObject->property(i).typeName())
			));
			classItem->addChild(propertyItem);
		}

		// Methods
		for (int i = metaObject->methodOffset(); i < metaObject->methodCount(); ++i)
		{
			const auto paramaterNames = metaObject->method(i).parameterNames();
			QString signature = metaObject->method(i).signature();

			if (paramaterNames.count() > 1)
			{
				auto splitSignature = signature.split(',');
				for (auto i = 0; i < paramaterNames.count() - 1; i++)
				{
					if (!paramaterNames[i].isEmpty())
					{
						splitSignature[i].append(' ').append(QString(paramaterNames[i]));
					}
				}

				signature = splitSignature.join(", ");
			}

			if (paramaterNames.count() > 0 && !paramaterNames.last().isEmpty())
			{
				signature.insert(signature.lastIndexOf(')'), QString(" ").append(QString(paramaterNames.last())));
			}

			const auto methodItem = new TreeWidgetItem(QStringList(QString("%1 [%2] %3 -> %4")
				.arg(accessTypeName[metaObject->method(i).access()])
				.arg(methodTypeName[metaObject->method(i).methodType()])
				.arg(signature)
				.arg(strcmp(metaObject->method(i).typeName(), "") ? metaObject->method(i).typeName() : "void")
			));
			classItem->addChild(methodItem);
		}

		this->m_items.append(classItem);
	}
}