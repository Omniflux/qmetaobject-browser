#pragma once

#include <QList>
#include <QStringList>
#include <QTreeWidgetItem>

#include "dzaction.h"
#include "dzpane.h"

class QObject;
class QMetaObject;
class QTreeWidget;

class OfQMetaObjectBrowserPaneAction : public DzPaneAction
{
    Q_OBJECT

public:
    OfQMetaObjectBrowserPaneAction() : DzPaneAction("OfQMetaObjectBrowserPane") {}
};

class OfQMetaObjectBrowserPane : public DzPane
{
    Q_OBJECT

public:
    OfQMetaObjectBrowserPane();
    virtual ~OfQMetaObjectBrowserPane() {};

public slots:
    virtual void refresh() override;

private:
    QStringList m_metaObjects;
    QTreeWidget* m_QMetaObjectTree;
    QList<QTreeWidgetItem*> m_items;

    void addClass(const QMetaObject* const metaObject);
    void addClass(const QObject* const object);

    static QObject* checkType(void* obj);
    static void causeAccessViolationIfNotQObject(const QObject* obj);
};

class TreeWidgetItem : public QTreeWidgetItem
{
public:
    TreeWidgetItem(const QStringList& strings, int type = Type) : QTreeWidgetItem(strings, type) {}

private:
    bool operator<(const QTreeWidgetItem& other) const
    {
        const auto column = treeWidget()->sortColumn();

        const auto bracketOpen = text(column).indexOf('[');
        const auto bracketClose = text(column).indexOf(']');
        const auto brackets = bracketOpen != -1 && bracketClose != -1;

        const auto otherBracketOpen = other.text(column).indexOf('[');
        const auto otherBracketClose = other.text(column).indexOf(']');
        const auto otherBrackets = otherBracketOpen != -1 && otherBracketClose != -1;

        if (brackets != otherBrackets)
        {
            return brackets < otherBrackets;
        }

        if (brackets)
        {
            const auto a = text(column).midRef(bracketOpen + 1, bracketClose - bracketOpen - 1);
            const auto b = other.text(column).midRef(otherBracketOpen + 1, otherBracketClose - otherBracketOpen - 1);

            if (a != b)
            {
                return a < b;
            }
        }

        return QTreeWidgetItem::operator<(other);
    }
};