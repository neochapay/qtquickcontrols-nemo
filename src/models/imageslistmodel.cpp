#include "imageslistmodel.h"

#include <QDir>

ImagesListModel::ImagesListModel(QObject *parent) :
    QAbstractListModel(parent)
{
    m_hash.insert(Qt::UserRole ,QByteArray("fileName"));
    m_hash.insert(Qt::UserRole+1 ,QByteArray("isDir"));
    m_hash.insert(Qt::UserRole+2 ,QByteArray("previews"));
}

int ImagesListModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_imagesList.count();
}

QVariant ImagesListModel::data(const QModelIndex &index, int role) const
{
    Q_UNUSED(role);
    if(!index.isValid())
    {
        return QVariant();
    }

    if(index.row() >= m_imagesList.size())
    {
        return QVariant();
    }

    ImagesListItem item = m_imagesList.at(index.row());
    switch (role)
    {
    case Qt::UserRole:
        return item.fileName;
    case Qt::UserRole+1:
        return item.isDir;
    case Qt::UserRole+2:
        return item.previews;
    default:
        return QVariant();
    }
}

QVariant ImagesListModel::get(const int idx) const
{
    if(idx >= m_imagesList.size())
    {
        return QVariant();
    }

    QMap<QString, QVariant> itemData;
    ImagesListItem item = m_imagesList.at(idx);

    itemData.insert("fileName",item.fileName);
    itemData.insert("isDir",item.isDir);
    itemData.insert("previews",item.previews);

    return QVariant(itemData);
}


void ImagesListModel::setRootDir(QString root)
{
    QDir rootDir(root);
    if(rootDir.exists() && m_rootDir != root)
    {
        m_rootDir = root;
        fill();
        emit rootDirChanged();
    }
}

void ImagesListModel::setRecursive(bool recursive)
{
    if(recursive != m_recursive)
    {
        m_recursive = recursive;
        fill();
        emit recursiveChanged();
    }
}

void ImagesListModel::setPreviewCout(int previewCout)
{
    if(previewCout != m_previewCount)
    {
        m_previewCount = previewCout;
        fill();
        emit previewCoutChanged();
    }
}

void ImagesListModel::fill()
{

}
