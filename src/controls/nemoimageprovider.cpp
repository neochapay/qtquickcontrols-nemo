/*
 * Copyright (C) 2013 Aleksi Suomalainen <suomalainen.aleksi@gmail.com>
 * Copyright (C) 2017 Sergey Chupligin <neochapay@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */
#include "nemoimageprovider.h"

#include <QFile>

NemoImageProvider::NemoImageProvider() :
    QQuickImageProvider(QQuickImageProvider::Image)
{
    m_iconsDirs.append("/usr/share/themes/glacier/meegotouch/icons");
    m_iconsDirs.append("/usr/share/themes/glacier/fontawesome/icons");
}

QImage NemoImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(size);
    Q_UNUSED(requestedSize);

    QString imageUrl = getImageUrl(id);
    if(imageUrl.length() > 0)
    {
        return QImage(imageUrl);
    }
    return QImage();
}

QPixmap NemoImageProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(size);
    Q_UNUSED(requestedSize);

    QString imageUrl = getImageUrl(id);
    if(imageUrl.length() > 0)
    {
        return QPixmap(imageUrl);
    }
    return QPixmap();
}

QString NemoImageProvider::getImageUrl(QString imageId)
{
    foreach (QString dir, m_iconsDirs)
    {
        QFile(dir+"/"+imageId).exists();
        return dir+"/"+imageId;
    }

    qWarning() << "Image " << imageId << " not found";
    return nullptr;
}
