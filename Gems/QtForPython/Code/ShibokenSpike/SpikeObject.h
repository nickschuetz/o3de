/*
 * Copyright (c) Contributors to the Open 3D Engine Project.
 * For complete copyright and license terms please see the LICENSE at the root of this distribution.
 *
 * SPDX-License-Identifier: Apache-2.0 OR MIT
 *
 */
#pragma once

#include <QObject>
#include <QString>

//! Minimal wrapped type used to exercise the add_shiboken_project code
//! generation path end to end (generator, typesystem resolution, wrapper
//! compile, module link, python import).
class SpikeObject : public QObject
{
public:
    using QObject::QObject;

    int addOne(int value) const
    {
        return value + 1;
    }

    QString greet(const QString& name) const
    {
        return QStringLiteral("hello ") + name;
    }
};
