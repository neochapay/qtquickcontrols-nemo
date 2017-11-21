/****************************************************************************************
**
** Copyright (C) 2017 Chupligin Sergey <neochapay@gmail.com>
** All rights reserved.
**
** You may use this file under the terms of BSD license as follows:
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are met:
**     * Redistributions of source code must retain the above copyright
**       notice, this list of conditions and the following disclaimer.
**     * Redistributions in binary form must reproduce the above copyright
**       notice, this list of conditions and the following disclaimer in the
**       documentation and/or other materials provided with the distribution.
**     * Neither the name of the author nor the
**       names of its contributors may be used to endorse or promote products
**       derived from this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
** ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
** WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
** DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
** ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
** (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
** LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
** ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
** SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**
****************************************************************************************/
#ifndef IMAGESLISTMODEL_H
#define IMAGESLISTMODEL_H

#include <QAbstractListModel>

class ImagesListModel : public QAbstractListModel
{
    Q_OBJECT
    struct ImagesListItem{
        QString fileName;
        QString path;
        bool isDir;
        QVariantList previews;
    };

    Q_PROPERTY(QString rootDir READ rootDir WRITE setRootDir NOTIFY rootDirChanged)
    Q_PROPERTY(bool showDirs READ showDirs WRITE setShowDirs NOTIFY showDirsChanged)
    Q_PROPERTY(int previewCout READ previewCout WRITE setPreviewCout NOTIFY previewCoutChanged)

public:
    explicit ImagesListModel(QObject *parent = 0);
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role) const;
    QHash<int, QByteArray> roleNames() const {return m_hash;}

    void setRootDir(QString root);
    void setShowDirs(bool showDirs);
    void setPreviewCout(int previewCout);

    QString rootDir(){return m_rootDir;}
    bool showDirs(){return m_showDirs;}
    int previewCout(){return m_previewCount;}

    Q_INVOKABLE int count(){return m_imagesList.count();}

public slots:
    QVariant get(const int idx) const;

signals:
    void rootDirChanged();
    void showDirsChanged();
    void previewCoutChanged();

private:
    QHash<int,QByteArray> m_hash;
    QList<ImagesListItem> m_imagesList;

    void fill();
    QVariantList loadDirPreview(QString dir);
    QStringList m_filters;

    QString m_rootDir;
    bool m_showDirs;
    int m_previewCount;
};

#endif // IMAGESLISTMODEL_H
