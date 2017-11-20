#include "imageslistmodel.h"

#include <QDir>
#include <QStandardPaths>

ImagesListModel::ImagesListModel(QObject *parent) :
    QAbstractListModel(parent)
{
    m_hash.insert(Qt::UserRole ,QByteArray("fileName"));
    m_hash.insert(Qt::UserRole+1 ,QByteArray("path"));
    m_hash.insert(Qt::UserRole+2 ,QByteArray("isDir"));
    m_hash.insert(Qt::UserRole+3 ,QByteArray("previews"));

    m_rootDir = QStandardPaths::standardLocations(QStandardPaths::PicturesLocation).first();
    m_previewCount = 4;

    m_filters << "*.png" << "*.jpg" << "*.bmp";
    fill();
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
        return item.path;
    case Qt::UserRole+2:
        return item.isDir;
    case Qt::UserRole+3:
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
    itemData.insert("path",item.path);
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

void ImagesListModel::setShowDirs(bool showDirs)
{
    if(showDirs != m_showDirs)
    {
        m_showDirs = showDirs;
        fill();
        emit showDirsChanged();
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
    m_imagesList.clear();

    QDir rootDir(m_rootDir);
    if(m_showDirs)
    {
        rootDir.setFilter(QDir::Dirs | QDir::NoSymLinks | QDir::NoDot | QDir::NoDotDot);
        for(int i=0; i < rootDir.entryList().count(); i++)
        {
            ImagesListItem item;
            item.fileName = rootDir.entryList().at(i);
            item.path = m_rootDir+"/"+rootDir.entryList().at(i);
            item.isDir = true;
            item.previews = loadDirPreview(item.fileName);

            m_imagesList.append(item);
        }
    }

    rootDir.setFilter(QDir::Files | QDir::NoSymLinks | QDir::NoDot | QDir::NoDotDot);
    rootDir.setSorting(QDir::DirsFirst | QDir::Time);
    rootDir.setNameFilters(m_filters);

    for(int i=0; i < rootDir.entryList().count(); i++)
    {
        ImagesListItem item;
        item.fileName = rootDir.entryList().at(i);
        item.path = m_rootDir+"/"+rootDir.entryList().at(i);
        item.isDir = false;
        item.previews = QStringList();

        m_imagesList.append(item);
    }

    dataChanged(createIndex(0, 0), createIndex(rowCount()-1, 0));
}

QStringList ImagesListModel::loadDirPreview(QString dir)
{
    QStringList previewFiles;

    QDir m_scanDir(dir);
    m_scanDir.setFilter(QDir::Files | QDir::NoSymLinks | QDir::NoDot | QDir::NoDotDot);
    m_scanDir.setSorting(QDir::Time);
    m_scanDir.setNameFilters(m_filters);

    int s_count = m_previewCount;
    if(s_count > m_scanDir.entryList().count())
    {
        s_count = m_scanDir.entryList().count();
    }

    for(int i=0; i < s_count; i++)
    {
        previewFiles << dir+"/"+m_scanDir.entryList().at(i);
    }
    return previewFiles;
}

